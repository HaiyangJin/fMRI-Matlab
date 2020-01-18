function fs_cosmo_searchlight(subjCode, ds_this, surfDef, hemiInfo, classPairs, classifier)
% This function performs the searchlight analysis with cosmoMVPA.
%
% Inputs:
%    subjCode       subject code in $SUBJECTS_DIR
%    ds_this        cosmo dataset
%    surf_def       surface denitions
%    hemi_info      'lh', 'rh', or 'both'
%    classPairs     the pairs to be classified for the searchlight
%    classifier     the classifier to be used
% Output:
%    For each hemispheres, the results will be saved as a label file saved 
%    at the subject label folder ($SUBJECTS_DIR/subjCode/label)
%    For the whole brain, the results will be saved as *.gii
%
% Created by Haiyang Jin (15/12/2019)

if nargin < 6 || isempty(classifier)
    [classifier, ~, nClass] = fs_cosmo_classifier;
else
    [classifier, ~, nClass] = fs_cosmo_classifier(classifier);
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
featureCount = 200;

% calculate the surficial neighborhood
fprintf('\n\nCalcualte the surficial neighborhood for %s (%s):\n',...
    subjCode, hemiInfo);
[nbrhood,vo,fo,~]=cosmo_surficial_neighborhood(ds_this,surfDef,...
    'count',featureCount);
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
    if ~all(ismember(thisPair, unique(ds_this.sa.labels)))
        continue;
    end
    
    % dataset for this classification
    thisPairMask = cosmo_match(ds_this.sa.labels, thisPair);
    ds_thisPair = cosmo_slice(ds_this, thisPairMask);
    
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
    dt_results = cosmo_searchlight(ds_thisPair,nbrhood,measure,measure_args);
    
    % print searchlight output
    fprintf('Dataset output:\n');
    cosmo_disp(dt_results);
    
    %% Save results as files
    % store searchlight results
    outputFn = sprintf('sl.svm.%s.%s-%s', hemiInfo, thisPair{1}, thisPair{2});
    
    if ismember(hemiInfo, {'lh', 'rh'})  % save as .label for each hemisphere
        fs_cosmo_map2label(dt_results, subjCode, outputFn, surfDef{1});
    elseif strcmp(hemiInfo, 'both')  % save as .gii for the whole brain
        outputFile = fullfile(getenv('SUBJECTS_DIR'), subjCode, 'label', outputFn);
        cosmo_map2surface(dt_results, [outputFile '.gii'], 'encoding','ASCII');
    end
    
    %% store counts
    
    
    %% save other information
    
    
end


end