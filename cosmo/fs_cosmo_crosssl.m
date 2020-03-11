function dt_sl = fs_cosmo_crosssl(ds, surfDef, featureCount, classPairs, ...
    subjCode, hemiInfo, classifier)
% dt_sl = fs_cosmo_crosssl(ds, surfDef, featureCount, classPairs, ...
%    subjCode, hemiInfo, classifier)
%
% This function performs the searchlight analysis with cosmoMVPA.
%
% Inputs:
%    ds              <structure> cosmo dataset.
%    surf_def        <cell of numeric array> surface denitions. The first
%                     element is the array of vertex number and coordiantes;
%                     the second element is the array of face number and
%                     coordinates. Both can be obtained by fs_cosmo_surfcoor.
%                     More information can be found in
%                     cosmo_surficial_neighborhood.m .
%    featureCount    <intenger> number of features to be used for each
%                     decoding.
%    classPairs      <cell of strings> the pairs to be classified for the
%                     searchlight; a PxQ (usually is 2) cell matrix for
%                     the pairs to be classified. Each row is one
%                     classfication pair.
%    subjCode        <string> subject code in $SUBJECTS_DIR.
%    hemi            <string> 'lh', 'rh', or 'both'.
%    classifier      <numeric> or <strings> or <cells> the classifiers
%                     to be used (only 1).
%
% Output:
%    dt_sl           <structure> data set of the searchlight results.
%    For each hemispheres, the results will be saved as a *.mgz file saved
%    at the subject label folder ($SUBJECTS_DIR/subjCode/surf)
%    For the whole brain, the results will be saved as *.gii
%
% Dependency:
%    CoSMoMVPA
%
% Created by Haiyang Jin (15-Dec-2019)

% if save the neighborhood infor and the rearchlight results
if nargin < 6 || isempty(subjCode) || isempty(hemiInfo)
    isSave = 0;
else
    isSave = 1;
end

if nargin < 7 || isempty(classifier)
    [classifier, ~, shortName, nClass] = cosmo_classifier;
else
    [classifier, ~, shortName, nClass] = cosmo_classifier(classifier);
end
% error if multiple classifiers are chosed
if nClass ~= 1
    error('Please choose only one classifier for search light analysis here.');
else
    classifier = classifier{1}; % convert cell to string
end

%% Set analysis parameters
% Use the cosmo_cross_validation_measure and set its parameters
% (classifier and partitions) in a measure_args struct.
measure = @cosmo_crossvalidation_measure;
measure_args = struct();

% Define which classifier to use, using a function handle.
% Alternatives are @cosmo_classify_{svm,nn,naive_bayes}
measure_args.classifier = classifier; % @cosmo_classify_libsvm;

% Define the feature neighborhood for each node on the surface
% - nbrhood has the neighborhood information
% - vo and fo are vertices and faces of the output surface
% - out2in is the mapping from output to input surface
% featureCount = 200;

% load the surficial neighborhood
if isSave
    nbhFn = sprintf('sl_cosmo_neighborhood_%s_%d.mat', hemiInfo, featureCount);
    nbhFilename = fullfile(getenv('SUBJECTS_DIR'), subjCode, 'surf', nbhFn);
    
    if exist(nbhFilename, 'file') % load the file if it is available
        fprintf('\n\nLoad the surficial neighborhood for %s (%s):\n',...
            subjCode, hemiInfo);
        
        temp = load(nbhFilename);
        
        if ~strcmp(temp.subjCode, subjCode) || ~strcmp(temp.hemiInfo, hemiInfo)
            error('The wrong file is loaded...');
        end
        % obtain the variables
        nbrhood = temp.nbrhood;
        vo = temp.to;
        fo = temp.fo;
        
        clear temp
    end
end

% calculate the surficial neighborhood if necessary
if ~exist('nbrhood', 'var') || ~exist('vo', 'var') || ~exist('fo', 'var')
    % calculate the surficial neighborhood
    fprintf('\n\nCalcualte the surficial neighborhood for %s (%s):\n',...
        subjCode, hemiInfo);
    [nbrhood,vo,fo,~]=cosmo_surficial_neighborhood(ds,surfDef,...
        'count',featureCount);
    
    if isSave
        % save the the surficial neighborhood file
        fprintf('\n\Saving the surficial neighborhood for %s (%s):\n',...
            subjCode, hemiInfo);
        save(nbhFilename, 'nbrhood', 'vo', 'fo', 'subjCode', 'hemiInfo','-v7.3');
    end
    
end

% print neighborhood
fprintf('Searchlight neighborhood definition:\n');
cosmo_disp(nbrhood);
fprintf('The output surface has %d vertices, %d nodes\n',...
    size(vo,1), size(fo,1));

% define the pairs for classification
nPairs = size(classPairs, 1);

for iPair = 1:nPairs
    
    % define this classification
    thisPair = classPairs(iPair, :);
    
    % skip if the pair is not available in this dataset
    if ~all(ismember(thisPair, unique(ds.sa.labels)))
        continue;
    end
    
    % dataset for this classification
    thisPairMask = cosmo_match(ds.sa.labels, thisPair);
    ds_thisPair = cosmo_slice(ds, thisPairMask);
    
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
    dt_sl = cosmo_searchlight(ds_thisPair,nbrhood,measure,measure_args);
    
    % print searchlight output
    fprintf('Dataset output:\n');
    cosmo_disp(dt_sl);
    
    %% Save results as *.mgz files
    if isSave
        % store searchlight results
        outputFn = sprintf('sl.%s.%s.%s-%s', shortName{1}, hemiInfo, thisPair{1}, thisPair{2});
        
        if ismember(hemiInfo, {'lh', 'rh'})  % save as .label for each hemisphere
            %         fs_save2label(dt_results.samples, subjCode, outputFn, surfDef{1});
            fs_savemgz(subjCode, dt_sl.samples', outputFn);
        elseif strcmp(hemiInfo, 'both')  % save as .gii for the whole brain
            outputFile = fullfile(getenv('SUBJECTS_DIR'), subjCode, 'surf', outputFn);
            cosmo_map2surface(dt_sl, [outputFile '.gii'], 'encoding','ASCII');
        end
    end
    
    %% store counts
    
    
    %% save other information
    
    
end

end