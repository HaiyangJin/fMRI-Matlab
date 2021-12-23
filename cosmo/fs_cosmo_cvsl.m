function [ds_cell, conCell] = fs_cosmo_cvsl(ds, classPairs, surfDef, sessCode, anaName, varargin)
% [ds_cell, conCell] = fs_cosmo_cvsl(ds, classPairs, surfDef, sessCode, anaName, varargin)
%
% This function performs the searchlight analysis with cosmoMVPA.
%
% Inputs:
%    ds              <struct> cosmo dataset.
%    classPairs      <cell str> the pairs to be classified for the
%                     searchlight; a PxQ (usually is 2) cell matrix for
%                     the pairs to be classified. Each row is one
%                     classfication pair. For custom contrasts, the first
%                     element is the names of the two conditions; the
%                     second element is the condition numbers in
%                     sa.targets. Example is {{'face', 'word'}, {[1, 2, 3,
%                     4], [5, 6, 7, 8]}}.
%    surf_def        <cell num> surface denitions. The first element is the
%                     array of vertex number and coordiantes; the second
%                     element is the array of face number and vertex indices.
%                     Both can be obtained by fs_cosmo_surfcoor. More 
%                     information can be found in cosmo_surficial_neighborhood.m .
%    sessCode        <str> subject code in $FUNCTIONALS.
%    anaName         <str> analysis name.
%
% Varargin:
% %%%%% cosmo_surficial_neighborhood settings %%%%%%%%%%%%%%%%
%    'metric'        <str> the method used for neighboor. Options are
%                     'geodesic' [default], 'dijkstra', 'Euclidean'.
%    'radius'        <num> the radius in mm. Default is 0. When 'areas'
%                     is not empty, 'radius' will be the starting radius
%                     for identifying neighbors within areaMax.
%    'count'         <int> number of features to be used for each
%                     decoding. Default is 0.
%    'area'          <num> the maximum area for the negighbors. Default
%                     is 100. 
% %%%%% cosmo_searchlight settings %%%%%%%%%%%%%%%%
%    'measure'       <funtion handel> the function/analysis to be run. The
%                     avaiable options are: @cosmo_crossvalidation_measure
%                     [default], @cosmo_correlation_measure,
%                     @cosmo_target_dsm_corr_measure.
%    'centerids'     <int vec> center indices. Default is [], i.e.,
%                     excludes vertices outside the brain mask.
%    'nproc'         <int> number of processors if Matlab parallel
%                     processing toolbox is available. Default is 1.
% %%%%% cross-validation settings %%%%%%%%%%%%%%%%
%    'partitioner'   <function handle> the method to set partition
%                     datasets. Available options for corss-validation are:
%                     @cosmo_nfold_partitioner [default],
%                     @cosmo_nchoosek_partitioner,
%                     @cosmo_balance_partitioner,
%                     @cosmo_oddeven_partitioner (will be used if 'measure'
%                     is @cosmo_correlation_measure).
%    'classifier'    <num> or <str> or <cell> the classifiers
%                     to be used (only 1).
% %%%%% other settings %%%%%%%%%%%%%%%%
%    'applyuseless'  <boo> apply cosmo_remove_useless_data to ds.
%                     Default is 0.
%    'applycortex'   <boo> only run searchlight on vertices in the
%                     ?h.cortex.label. Default is 0.
%    'outprefix'     <str> strings to be added at the beginning of the
%                     ouput folder (the pseudo-analysis folder). Default is
%                     'sl'.
%    'maskedvalue'   <num> the default (accuracy) values for masked
%                     vertices. Default is -999.
%    'nbrstr'        <str> strings to be added to the nbr files. Default
%                     is ''.
%
% Output:
%    ds_cell         <struct> data sets of the searchlight results.
%    conCell         <cell str> the contrast for each dataset in ds_cell.
%    For each hemispheres, the results will be saved as a *.mgz file in
%    funcDir/sessCode/bold/analysisFolder/contrastFolder/.
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
    'area', 100, ... % in mm^2
    ... %%% cosmo_searchlight settings %%%
    'measure', @cosmo_crossvalidation_measure, ...
    'centerids', [], ... % all indices.
    'nproc', 1, ...
    ... %%% cross-validation settings %%%
    'partitioner', @cosmo_nfold_partitioner, ...
    'classifier', '', ... % libsvm will be used.
    'classopt', {{}}, ...
    ... %%% other settings %%%
    'applyuseless', 0, ...
    'applycortex', 0, ...
    'outprefix', 'sl', ...
    'maskedvalue', -999, ...
    'nbrstr', '' ...
    );

% parse options
opt=fm_mergestruct(defaultOpt, varargin{:});
%%% cosmo_surficial_neighboor(_area) %%%
metric = opt.metric; % 'euclidean'; % method used for distance
radius = opt.radius;
count = opt.count;
area = opt.area;
%%% cosmo_searchlight %%%
measure = opt.measure;
center_ids = opt.centerids;
%%% crossvalidation settings %%%
classifier = opt.classifier;
partitioner = opt.partitioner;
%%% other settings %%%
nbrStr = opt.nbrstr;

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
hemi = fs_2template(anaName, {'lh', 'rh'});

% decide whose surface information will be used
subjCode = fs_subjcode(sessCode);
trgSubj = fs_trgsubj(subjCode, template);

% use oddeven for split-half correlations
if strcmp(func2str(measure), 'cosmo_correlation_measure')
    partitioner = @cosmo_oddeven_partitioner;
end

%% Neighborhood
% which method is used for neighbors
nbr_args.metric = metric;
if radius ~= 0
    nbr_args.radius = radius;
    nbrStr = sprintf('%s_%s_r%d', nbrStr, metric, radius);
elseif count ~= 0
    nbr_args.count = count;
    nbrStr = sprintf('%s_%s_c%d', nbrStr, metric, count);
elseif ~isempty(area)
    nbr_args.area = area;
    nbrStr = sprintf('%s_%s_a%d', nbrStr, metric, area);
else
    error(['Please define the method for identifying neighboorhood.' ...
        'e.g., set ''radius'' or ''count''']);
end

% Define the feature neighborhood for each node on the surface
% load the surficial neighborhood
nbhFn = sprintf('sl_cosmo_nbr_%s_%s_%s.mat', hemi, trgSubj, nbrStr);
% the target folder
if strcmp(trgSubj, 'fsaverage')
    saveSubj = 'fsaverageSL';
    accPath = fullfile(getenv('SUBJECTS_DIR'), saveSubj, 'surf');
    fm_mkdir(accPath);
else
    saveSubj = trgSubj;
end

% the temporary neighborhood file to be saved/read
nbhFilename = fullfile(getenv('SUBJECTS_DIR'), saveSubj, 'surf', nbhFn);
if exist(nbhFilename, 'file') % load the file if it is available
    fprintf('\nLoading the surficial neighborhood (%s) for %s (%s):\n',...
        nbhFn, trgSubj, hemi);

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
    fprintf('\n\nGenerating the surficial neighborhood (%s) for %s (%s):\n',...
        nbhFn, trgSubj, hemi);

    [nbrhood,vo,fo]=cosmo_surficial_neighborhood(ds,surfDef,nbr_args);

    % save the the surficial neighborhood file
    fprintf('\nSaving the surficial neighborhood (%s) for %s (%s):\n',...
        nbhFn, trgSubj, hemi);
    save(nbhFilename, 'nbrhood', 'vo', 'fo', 'trgSubj', 'hemi',...
        'template', 'metric', '-v7.3');
end

% print neighborhood
fprintf('Searchlight neighborhood definition:\n');
cosmo_disp(nbrhood);
fprintf('The output surface has %d vertices, %d nodes\n',...
    size(vo,1), size(fo,1));

%% Set center_ids
if ismember(hemi, {'lh', 'rh'}) && isempty(center_ids)

    % remove uselessdta
    if opt.applyuseless
        [~, useMask] = cosmo_remove_useless_data(ds);
        useVtx = find(useMask);
    else
        useVtx = 1:size(ds.samples, 2);
    end

    % mask applied to searchlight (2)
    if opt.applycortex
        % load ?h.cortex.label as a mask for surface
        cortexVtx = fs_cortexmask(trgSubj, hemi);
    else
        cortexVtx = 1:size(ds.samples, 2);
    end

    tempIn = sort(intersect(cortexVtx, useVtx));

    % only keep neighborhood within <tempIn>
    isRemoved = cellfun(@(x) sum(~ismembc(sort(x), tempIn))>0, nbrhood.neighbors);
    rmvVtx = nbrhood.fa.node_indices(isRemoved);

    % combine center_ids
    center_ids = setdiff(tempIn, rmvVtx);

elseif isempty(center_ids)
    % use all vertices
    center_ids = 1:size(ds.samples, 2);
end

%% Set analysis parameters
% measure_args = struct();
measure_args = fm_mergestruct(opt.classopt);

% Define which classifier to use, using a function handle.
measure_args.classifier = classifier; % @cosmo_classify_libsvm;
% folders for saving results (Pseudo-analysis folder)
anaFolder = [opt.outprefix '_' nbrStr '_' anaName];

nPairs = size(classPairs, 1);
ds_cell = cell(nPairs, 1);
conCell = cell(nPairs, 1);

for iPair = 1:nPairs

    % define this classification
    thisPair = classPairs(iPair, :);

    if ischar(thisPair{1})
        % skip if the pair is not available in this dataset
        if ~all(ismember(thisPair, unique(ds.sa.labels)))
            warning('Cannot find %s vs. %s in the dataset.', thisPair{:});
            continue;
        end

        % dataset for this classification
        thisPairMask = cosmo_match(ds.sa.labels, thisPair);
        ds_thisPair = cosmo_slice(ds, thisPairMask);
        % (Pseudo-contrast folder)
        conFolder = sprintf('%s-vs-%s', thisPair{:});
    else
        % custom contrasts
        % the first element is the names and the second element is the
        % condition number of that contrast.
        conName = thisPair{1};
        conFolder = sprintf('%s-vs-%s', conName{:});

        conCode = thisPair{2};
        if max(horzcat(conCode{:})) > max(ds.sa.targets)
            warning('The index is out of the target range(max: %d).', max(ds.sa.targets));
            continue;
        end

        % reset the targets and labels
        targetTemp = NaN(size(ds.sa.targets));
        labelTemp = cell(size(ds.sa.labels));

        actCon = ismember(ds.sa.targets, conCode{1});
        deactCon = ismember(ds.sa.targets, conCode{2});

        targetTemp(actCon) = 1;
        targetTemp(deactCon) = 2;

        labelTemp(actCon) = conName(1);
        labelTemp(deactCon) = conName(2);

        tempds = ds;
        tempds.sa.targets = targetTemp;
        tempds.sa.labels = labelTemp;

        tempds = cosmo_slice(tempds, ismember(tempds.sa.targets, [1,2]));

        % get the mean for the two condition
        ds_thisPair = cosmo_fx(tempds, @(x)mean(x,1), {'chunks', 'targets'}, 1);

    end

    %% Set partition scheme.
    measure_args.partitions = partitioner(ds_thisPair);

    % print measure and arguments
    fprintf('Searchlight measure:\n');
    cosmo_disp(measure);
    fprintf('Searchlight measure arguments:\n');
    cosmo_disp(measure_args);

    %% Run the searchlight
    ds_sl = cosmo_searchlight(ds_thisPair,nbrhood,measure,measure_args,...
        'center_ids', center_ids, 'nproc', opt.nproc);

    % print searchlight output
    fprintf('Dataset output:\n');
    cosmo_disp(ds_sl);

    % set the accuracy for non-cortex vertices as -1
    accuracy = ones(size(vo, 1), 1) * opt.maskedvalue;
    accuracy(center_ids) = ds_sl.samples';

    %% Save results as *.mgz files

    % store searchlight results
    if isfield(measure_args, 'normalization') && ~isempty(measure_args.normalization)
        normStr = ['.' measure_args.normalization];
    else
        normStr = '';
    end
    accFn = sprintf('sl.%s%s.acc', shortName{1}, normStr);
    accPath = fullfile(getenv('FUNCTIONALS_DIR'), sessCode, 'bold', anaFolder, conFolder);

    if ismember(hemi, {'lh', 'rh'})
        if ~exist(accPath, 'dir'); mkdir(accPath); end
        % save the accuracy as *.mgz
        fs_savemgz(trgSubj, accuracy, accFn, accPath, hemi);
    elseif strcmp(hemi, 'lhrh')  % save as .gii for the whole brain
        outputFile = fullfile(accPath, accFn);
        cosmo_map2surface(ds_sl, [outputFile '.gii'], 'encoding','ASCII');
    end

    % save other information
    ds_cell{iPair, 1} = ds_sl;
    conCell{iPair, 1} = conFolder;

end  % iPair

end