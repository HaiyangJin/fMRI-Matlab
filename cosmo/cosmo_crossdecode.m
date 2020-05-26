function mvpaTable = cosmo_crossdecode(ds, classPairs, condInfo, classifiers)
% mvpaTable = cosmo_crossdecode(ds, classPairs, condInfo, classifiers)
%
% This function performs leave-one-out cross validation classification with
% CoSMoMVPA.
%
% Inputs:
%    ds               <strucutre> dataset obtained from fs_cosmo_subjds.
%    classPairs       <cell of strings> a PxQ (usually is 2) cell matrix
%                     for the pairs to be classified. Each row is one
%                     classfication pair.
%    condInfo         <structure> Extra information to be saved
%                     in mvpaTable. E.g., the condition information
%                     obtained from fs_cosmo_subjds.
%    classifiers      <numeric> or <strings> or <cells> the classifiers
%                     to be used (can be more than 1).
%
% Output:
%    mvpaTable       the MVPA result table
%
% Dependency:
%    CoSMoMVPA
%
% Created by Haiyang Jin (12-Dec-2019)

if ~exist('condInfo', 'var') || isempty(condInfo)
    condInfo = '';
end

if ~exist('classifiers', 'var') || isempty(classifiers)
    [classifiers, classNames, ~, nClass] = cosmo_classifier;
else
    [classifiers, classNames, ~, nClass] = cosmo_classifier(classifiers);
end

% MVPA settings
measure = @cosmo_crossvalidation_measure;  % function handle
measure_args.output = 'fold_predictions';

% remove constant features
ds = cosmo_remove_useless_data(ds);

% pairs for classification
nPair = size(classPairs, 1);

% empty cell for saving data later
mvpaCell = cell(nPair, nClass);
accTable = table;

% Run analysis for each pair
for iPair = 1:nPair
    
    % define this classification and its mask
    thisPair = classPairs(iPair, :);
    
    % skip if the pair is not available in this dataset
    if ~all(ismember(thisPair, unique(ds.sa.labels)))
        continue;
    end
    
    % dataset for this classification
    thisPairMask = cosmo_match(ds.sa.labels, thisPair);
    ds_thisPair = cosmo_slice(ds, thisPairMask);
    
    % set the partitions for this dataset
    measure_args.partitions = cosmo_nfold_partitioner(ds_thisPair); % leave 1 out
    
    for iClass = 1:nClass
        
        tmpMVPA = table;
        % the classifier for this analysis
        measure_args.classifier = classifiers{iClass};
        thisClassfifier = classNames{iClass};
        
        ds_predicted = measure(ds_thisPair, measure_args);
        
        % calculate the confusion matrix
        thisConMatrix = cosmo_confusion_matrix(ds_predicted);
        
        % calculate and display the accuracy
        accuracy = mean(ds_predicted.sa.targets == ds_predicted.samples);
        desc=sprintf('%s: accuracy %.1f%%', thisClassfifier, accuracy*100);
        fprintf('%s\n',desc);
        
        % save the results
        nRowTemp = numel(ds_predicted.sa.targets);
        tmpMVPA.ClassifyPair = repmat({[thisPair{1}, '-', thisPair{2}]}, nRowTemp, 1);
        tmpMVPA.Classifier = repmat({thisClassfifier}, nRowTemp, 1);
        
        tmpMVPA.Run = ds_predicted.sa.folds;
        tmpMVPA.Predicted = ds_predicted.samples;
        tmpMVPA.Targets = ds_predicted.sa.targets;
        tmpMVPA.ACC = ds_predicted.samples == ds_predicted.sa.targets;
        
        tmpMVPA.Confusion = repmat({thisConMatrix}, nRowTemp, 1);
        
        % save the tmp MVPA table
        mvpaCell(iPair, iClass) = {tmpMVPA};
    end
    
    % save all tables together
    accTable = vertcat(mvpaCell{:});
    
end

% combine mvpa data with condition information
nRow = size(accTable, 1);
if ~nRow || isempty(condInfo)
    mvpaTable = table;
else
    mvpaTable = [repmat(condInfo, nRow, 1), accTable];
end

end