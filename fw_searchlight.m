function svm_results = fw_searchlight(subjCode_bold, expCode, file_surfcoor, combineHemi, classifier)
% This function does the searchlight analyses for the faceword project
% with CoSMoMVPA. Data were analyzed with FreeSurfer.
%
% Created by Haiyang (24/11/2019)
% 
% Inputs:
%    subjCode_bold      the name of subject's bold folder
%    expCode            experiment code (1 or 2)
%    file_surfcoor      the coordinate file for vertices ('inflated',
%                       'white', 'pial') 
%    combineHemi      if the data of two hemispheres will be combined
%                       (default is no)
%    classifier         classifier function handle
% Output:
%    the results will be saved as a label file saved at the subject label
%    folder ($SUBJECTS_DIR/subjCode/label)
%
% subjCode_bold = 'faceword01_self';
% expCode = 1;

cosmo_warning('once');

if nargin < 3 || isempty(file_surfcoor)
    file_surfcoor = 'inflated';
end
if nargin < 4 || isempty(combineHemi)
    combineHemi = 0;
end
if nargin < 5 || isempty(classifier)
    classifier = @cosmo_classify_libsvm;
end


%% Preparation
FS = fs_setup;
hemis = FS.hemis;
nHemi = FS.nHemi;
fMRIPath = fullfile(FS.subjects, '..', 'Data_fMRI');

% check if there is the functional subject folder
subjPathBold = fullfile(fMRIPath, subjCode_bold);
if ~exist(subjPathBold, 'dir')
    error('Cannot find %s in the functional folder (%s).', subjCode_bold, fMRIPath);
end

% check if there is surface folder
subjCode = fs_subjcode(subjCode_bold, projStr.fMRI); % subjCode in SUBJECTS_DIR
subjPath = fullfile(FS.subjects, subjCode);
if ~exist(subjPath, 'dir')
    error('Cannot find %s in FreeSurfer subject folder (SUBJECTS_DIR).', subjCode);
end

% define the pairs for classification
classifyPairs_E1 = {'face_intact', 'word_intact';
    'face_intact', 'face_exchange';
    'word_intact', 'word_exchange';
    'face_top', 'face_bottom';
    'word_top', 'word_bottom';
    };

classifyPairs_E2 = {'Chinese_intact', 'English_intact';
    'Chinese_intact', 'Chinese_exchange';
    'Chinese_top', 'Chinese_bottom';
    'English_intact', 'English_exchange';
    'English_top', 'English_bottom'};

classExps = {classifyPairs_E1, classifyPairs_E2};
classifyPairs = classExps{expCode};
nPairs = size(classifyPairs, 1);

% load vertex and face coordinates
[vtxCell, faceCell] = fs_cosmo_surfcoor(subjCode, file_surfcoor, combineHemi);


%% Load functional data
% the path to the bold folder
boldPath = fullfile(fMRIPath, subjCode_bold, 'bold');

% obtain the run names
runList = importdata(fullfile(boldPath, 'run_Main.txt'))';
runNames = arrayfun(@(x) sprintf('%03d', x), runList, 'UniformOutput', false);
nRun = numel(runList);

% Pre-define the cell array for saving ds 
ds_cell = cell(nRun, nHemi + combineHemi); 

% load functional data for each run separately
for iRun = 1:nRun
    
    % load data for each hemisphere separately (and combined later)
    nVertices = 0;
    for iHemi = 1:nHemi
        % the bold file
        analysisName = ['main_sm0_self', num2str(iRun), '.', hemis{iHemi}];
        thisBoldFilename = fullfile(boldPath, analysisName, 'beta.nii.gz'); %%% here (the functional data file)
        
        % load paradigm file
        parFileDir = fullfile(boldPath, runNames{iRun}, 'main.par');
        parInfo = fs_readpar(parFileDir);
        
        % load the nifti from FreeSurfer and add .sa .fa
        this_ds = fs_cosmo_surface(thisBoldFilename, ...
            'targets', parInfo.Condition, ...
            'labels', parInfo.Label, ...
            'chunks', repmat(iRun, size(parInfo, 1), 1)); 
                
        % run if combine data from both hemispheres
        if combineHemi
            
            % update the attribute number for further stack
            if iHemi == 1
                nVertices = numel(this_ds.a.fdim.values{1, 1});
            else
                this_ds.fa.node_indices = this_ds.fa.node_nidices + nVertices;
            end
            
        end
        
        % save the dt in a cell for further stacking
        ds_cell(iRun, iHemi) = {this_ds};
        
    end
    
    if combineHemi
        % combine the dt for the two hemispheres
        ds_cell(iRun, 3) = cosmo_stack(ds_cell(iRun, 1:2), 2);
    end
    
end


%% Set analysis parameters
% Use the cosmo_cross_validation_measure and set its parameters
% (classifier and partitions) in a measure_args struct.
measure = @cosmo_crossvalidation_measure;
measure_args = struct();

% Define which classifier to use, using a function handle.
% Alternatives are @cosmo_classify_{svm,nn,naive_bayes}
measure_args.classifier = classifier; % @cosmo_classify_lda;

%% conduct searchlight for two hemisphere seprately
for iHemi = 1:2
    
    thisHemi = hemis{iHemi}; % hemisphere name
    
    % Define the feature neighborhood for each node on the surface
    % - nbrhood has the neighborhood information
    % - vo and fo are vertices and faces of the output surface
    % - out2in is the mapping from output to input surface
    feature_count = 200;
    
    % ds for this hemisphere
    ds_hemi = cosmo_stack(ds_cell(:, iHemi));
    
    %% Surface setting 
    % white, pial, surface for this hemisphere
    v_inf = vtxCell{iHemi};
    f_inf = faceCell{iHemi};
    surf_def = {v_inf, f_inf};
    
    fprintf('\n\nCalcualte the surficial neighborhood for %s (%s):\n',...
        subjCode,thisHemi);
    [nbrhood,vo,fo,~]=cosmo_surficial_neighborhood(ds_hemi,surf_def,...
        'count',feature_count);
    % print neighborhood
    fprintf('Searchlight neighborhood definition:\n');
    cosmo_disp(nbrhood);
    fprintf('The output surface has %d vertices, %d nodes\n',...
        size(vo,1), size(fo,1));
    
    for iPair = 1:nPairs
        
        % define this classification
        thisPair = classifyPairs(iPair, :);
        thisPairMask = cosmo_match(ds_hemi.sa.labels, thisPair);
        
        % dataset for this classification
        ds_thisPair = cosmo_slice(ds_hemi, thisPairMask);
        
        %% Set partition scheme. odd_even is fast; for publication-quality analysis
        % nfold_partitioner is recommended.
        % Alternatives are:
        % - cosmo_nfold_partitioner    (take-one-chunk-out crossvalidation)
        % - cosmo_nchoosek_partitioner (take-K-chunks-out  "             ").
        measure_args.partitions = cosmo_nfold_partitioner(ds_thisPair);
        
        % print measure and arguments
        fprintf('Searchlight measure:\n');
        cosmo_disp(measure);
        fprintf('Searchlight measure arguments:\n');
        cosmo_disp(measure_args);
        
        %% Run the searchlight
        svm_results = cosmo_searchlight(ds_thisPair,nbrhood,measure,measure_args);
        
        % print searchlight output
        fprintf('Dataset output:\n');
        cosmo_disp(svm_results);
        
        %% Save results
        % store searchlight results
        output_filename = sprintf('sl.svm.%s.%s-%s', thisHemi, thisPair{1}, thisPair{2});
        output_fn = fullfile(subjPath, 'label', output_filename);
%         save([output_fn '.mat'], 'svm_results');
        fs_cosmo_map2label(svm_results, output_fn, v_inf, subjCode);
%         cosmo_map2surface(svm_results, [output_fn '.gii'], 'encoding','ASCII');
%         cosmo_map2surface(svm_results, [output_fn '.niml.dset'], 'encoding', 'ASCII');
        
        %% store counts
        
        
    end
end
