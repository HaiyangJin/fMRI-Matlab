function dt_sl = fs_cosmo_cvsl(ds, classPairs, surfDef, sessCode, anaName, varargin)
% dt_sl = fs_cosmo_cvsl(ds, classPairs, surfDef, sessCode, anaName, varargin)
%
% This function performs the searchlight analysis with cosmoMVPA.
%
% Inputs:
%    ds              <structure> cosmo dataset.
%    classPairs      <cell of strings> the pairs to be classified for the
%                     searchlight; a PxQ (usually is 2) cell matrix for
%                     the pairs to be classified. Each row is one
%                     classfication pair.
%    surf_def        <cell of numeric array> surface denitions. The first
%                     element is the array of vertex number and coordiantes;
%                     the second element is the array of face number and
%                     vertex indices. Both can be obtained by
%                     fs_cosmo_surfcoor. More information can be found in
%                     cosmo_surficial_neighborhood.m .
%    sessCode        <string> subject code in $FUNCTIONALS.
%    anaName         <string> analysis name.
%
% Varargin:
% %%%%% cosmo_surficial_neighborhood settings %%%%%%%%%%%%%%%%
%    'metric'        <string> the method used for neighboor. Options are
%                     'geodesic' [default], 'dijkstra', 'Euclidean'.
%    'radius'        <numeric> the radius in mm. Default is 0.
%    'count'         <integer> number of features to be used for each
%                     decoding. Default is 0.
% %%%%% cosmo_searchlight settings %%%%%%%%%%%%%%%%
%    'measure'       <funtion handel> the function/analysis to be run. The
%                     avaiable options are: @cosmo_crossvalidation_measure
%                     [default], @cosmo_correlation_measure,
%                     @cosmo_target_dsm_corr_measure.
%    'centerids'     <intger vector> center indices. Default is [], i.e.,
%                     excludes vertices outside the brain mask.
%    'nproc'         <integer> number of processors if Matlab parallel
%                     processing toolbox is available. Default is 1.
% %%%%% cross-validation settings %%%%%%%%%%%%%%%%
%    'partitioner'   <function handle> the method to set partition
%                     datasets. Available options for corss-validation are:
%                     @cosmo_nfold_partitioner [default],
%                     @cosmo_nchoosek_partitioner,
%                     @cosmo_balance_partitioner,
%                     @cosmo_oddeven_partitioner (will be used if 'measure'
%                     is @cosmo_correlation_measure).
%    'classifier'    <numeric> or <strings> or <cells> the classifiers
%                     to be used (only 1).
% %%%%% other settings %%%%%%%%%%%%%%%%
%    'outprefix'     <string> strings to be added at the beginning of the
%                     ouput folder (the pseudo-analysis folder). Default is
%                     'sl'.
%    'maskedvalue'   <numeric> the default (accuracy) values for masked
%                     vertices. Default is -999.
%    'nbrstr'        <string> strings to be added to the nbr files. Default
%                     is ''.
%    'funcPath'      <string> where to save the output. Default is
%                     $FUNCTIONALS_DIR.
%
% Output:
%    dt_sl           <structure> data set of the searchlight results.
%    For each hemispheres, the results will be saved as a *.mgz file in
%    funcPath/sessCode/bold/analysisFolder/contrastFolder/.
%    For the whole brain, the results will be saved as *.gii.
%
% Dependency:
%    CoSMoMVPA
%
% Created by Haiyang Jin (15-Dec-2019)

% default options
defaultOpt=struct(...
    ... %%% cosmo_surficial_neighboor settings %%%%
    'metric', 'geodesic', ...
    'radius', 0, ... % in mm
    'count', 0, ...
    ... %%% cosmo_searchlight settings %%%
    'measure', @cosmo_crossvalidation_measure, ...
    'centerids', [], ... % all indices.
    'nproc', 1, ...
    ... %%% cross-validation settings %%%
    'partitioner', @cosmo_nfold_partitioner, ...
    'classifier', '', ... % libsvm will be used.
    ... %%% other settings %%%
    'outprefix', 'sl', ...
    'maskedvalue', -999, ...
    'nbrstr', '', ...
    'funcpath', getenv('FUNCTIONALS_DIR') ...
    );

% parse options
options=fs_mergestruct(defaultOpt, varargin{:});
%%% cosmo_surficial_neighboor %%%
metric = options.metric; % 'euclidean'; % method used for distance
radius = options.radius;
count = options.count;
%%% cosmo_searchlight %%%
measure = options.measure;
center_ids = options.centerids;
nproc = options.nproc;
%%% crossvalidation settings %%%
classifier = options.classifier;
partitioner = options.partitioner;
%%% other settings %%%
outPrefix = options.outprefix;
maskedValue = options.maskedvalue;
nbrStr = options.nbrstr;
funcPath = options.funcpath;

% pre-process classifer
if isempty(classifier)
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

template = fs_2template(anaName, '', 'fsaverage');
hemi = fs_2template(anaName, {'lh', 'rh'}, 'both');

% decide whose surface information will be used
trgSubj = fs_trgsubj(fs_subjcode(sessCode, funcPath), template);

if ismember(hemi, {'lh', 'rh'})
    % load ?h.cortex.label as a mask for surface
    vtxMask = fs_cortexmask(trgSubj, hemi);
else
    vtxMask = 1:size(ds.samples, 2);
end

% method used for distance
metric = 'geodesic'; % 'euclidean';

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
nbhFn = sprintf('sl_cosmo_neighborhood_%s_%d.mat', hemi, featureCount);
% the target folder
if strcmp(subjCode, 'fsaverage')
    saveSubj = 'fsaverageSL';
    accPath = fullfile(getenv('SUBJECTS_DIR'), saveSubj, 'surf');
    if ~exist(accPath, 'dir'); mkdir(accPath); end
else
    saveSubj = subjCode;
end

% the temporary neighborhood file to be saved/read
nbhFilename = fullfile(getenv('SUBJECTS_DIR'), saveSubj, 'surf', nbhFn);
if exist(nbhFilename, 'file') % load the file if it is available
    fprintf('\n\nLoad the surficial neighborhood for %s (%s):\n',...
        trgSubj, hemi);
    
    temp = load(nbhFilename);
    
    if ~strcmp(temp.trgSubj, trgSubj) || ~strcmp(temp.hemi, hemi)
        error('The wrong file is loaded...');
    end
    % obtain the variables
    nbrhood = temp.nbrhood;
    vo = temp.vo;
    fo = temp.fo;
    
    clear temp
end

% calculate the surficial neighborhood if necessary
if ~exist('nbrhood', 'var') || ~exist('vo', 'var') || ~exist('fo', 'var')
    % calculate the surficial neighborhood
    fprintf('\n\nGenerating the surficial neighborhood for %s (%s):\n',...
        trgSubj, hemi);
    [nbrhood,vo,fo,~]=cosmo_surficial_neighborhood(ds,surfDef,...
        'radius', r , 'metric', metric); % 'count',featureCount,
    
    % save the the surficial neighborhood file
    fprintf('\nSaving the surficial neighborhood for %s (%s):\n',...
        trgSubj, hemi);
    save(nbhFilename, 'nbrhood', 'vo', 'fo', 'trgSubj', 'hemi',...
        'template', 'metric', '-v7.3');
end

% print neighborhood
fprintf('Searchlight neighborhood definition:\n');
cosmo_disp(nbrhood);
fprintf('The output surface has %d vertices, %d nodes\n',...
    size(vo,1), size(fo,1));

% folders for saving results (Pseudo-analysis folder)
anaFolder = [outPrefix '_' anaName];

% define the pairs for classification
nPairs = size(classPairs, 1);

for iPair = 1:nPairs
    
    % define this classification
    thisPair = classPairs(iPair, :);
    
    % skip if the pair is not available in this dataset
    if ~all(ismember(thisPair, unique(ds.sa.labels)))
        warning('Cannot find %s vs. %s in the dataset.', thisPair{:});
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
    dt_sl = cosmo_searchlight(ds_thisPair,nbrhood,measure,measure_args,...
        'center_ids', center_ids, 'nproc', nproc);
    
    % print searchlight output
    fprintf('Dataset output:\n');
    cosmo_disp(dt_sl);
    
    % set the accuracy for non-cortex vertices as -1
    accuracy = ones(size(vo, 1), 1) * maskedValue;
    accuracy(vtxMask) = dt_sl.samples';
    
    %% Save results as *.mgz files
    % (Pseudo-contrast folder)
    conFolder = sprintf('%s-vs-%s', thisPair{:});
    
    % store searchlight results
    accFn = sprintf('sl.%s.%s.acc', shortName{1}, hemi);
    accPath = fullfile(funcPath, sessCode, 'bold', anaFolder, conFolder);
    
    if ismember(hemi, {'lh', 'rh'})
        if ~exist(accPath, 'dir'); mkdir(accPath); end
        % save the accuracy as *.mgz
        fs_savemgz(trgSubj, accuracy, accFn, accPath, hemi);
    elseif strcmp(hemi, 'both')  % save as .gii for the whole brain
        outputFile = fullfile(accPath, accFn);
        cosmo_map2surface(dt_sl, [outputFile '.gii'], 'encoding','ASCII');
    end
    
    %% store counts
    
    
    %% save other information
    
    
end  % iPair

end