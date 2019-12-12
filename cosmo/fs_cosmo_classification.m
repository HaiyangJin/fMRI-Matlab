function mvpa_table = fs_cosmo_classification(ds_subj, uni_info, classPairs, classifiers)
% mvpa_table = fs_cosmo_classification(ds_subj, uni_info, classPairs, classifiers)
% This function performs leave-one-out crossvalidation classification with CoSMoMVPA.
%
% Inputs:
%    ds_subj          dataset obtained from fs_fun_uni_cosmo_ds.
%    uni_info         the condition information obtained from fs_fun_uni_cosmo_ds.
%    classPairs       the pairs to be classified
%    classifiers      the classifiers to be used (could be more than 1)
% Output:
%    mvpa_table       the MVPA result table
%
% Created by Haiyang Jin (12/12/2019)

if nargin < 4 || isempty(classifiers)
    [classifiers, class_names, nClass] = fs_cosmo_classifier;
else
    [classifiers, class_names, nClass] = fs_cosmo_classifier(classifiers);
end

% MVPA settings
measure = @cosmo_crossvalidation_measure;  % function handle
args.output = 'fold_predictions';

% remove constant features
ds_subj = cosmo_remove_useless_data(ds_subj);

% pairs for classification
nPair = size(classPairs, 1);

% empty cell for saving data later
mvpaCell = cell(nPair, nClass);
ACC_table = table;

% Run analysis for each pair
for iPair = 1:nPair
    
    % define this classification and its mask
    thisPair = classPairs(iPair, :);
    
    % skip if the pair is not available in this dataset
    if ~all(ismember(thisPair, unique(ds_subj.sa.labels)))
        continue;
    end
    
    % dataset for this classification
    thisPairMask = cosmo_match(ds_subj.sa.labels, thisPair);
    ds_thisPair = cosmo_slice(ds_subj, thisPairMask);
    
    % set the partitions for this dataset
    args.partitions = cosmo_nfold_partitioner(ds_thisPair); % leave 1 out
    
    for iClass = 1:nClass
        
        tmpMVPA = table;
        % the classifier for this analysis
        args.classifier = classifiers{iClass};
        thisClassfifier = class_names{iClass};
        
        predicted_ds = measure(ds_thisPair, args);
        
        % calculate the confusion matrix
        thisConMatrix = cosmo_confusion_matrix(predicted_ds);
        
        % calculate and display the accuracy
        accuracy = mean(predicted_ds.sa.targets == predicted_ds.samples);
        desc=sprintf('%s: accuracy %.1f%%', thisClassfifier, accuracy*100);
        fprintf('%s\n',desc);
        
        % save the results
        nRowTemp = numel(predicted_ds.sa.targets);
        tmpMVPA.ClassifyPair = repmat({[thisPair{1}, '-', thisPair{2}]}, nRowTemp, 1);
        tmpMVPA.Classifier = repmat({thisClassfifier}, nRowTemp, 1);
        
        tmpMVPA.Run = predicted_ds.sa.folds;
        tmpMVPA.Predicted = predicted_ds.samples;
        tmpMVPA.Targets = predicted_ds.sa.targets;
        tmpMVPA.ACC = predicted_ds.samples == predicted_ds.sa.targets;
        
        tmpMVPA.Confusion = repmat({thisConMatrix}, nRowTemp, 1);
        
        % save the tmp MVPA table
        mvpaCell(iPair, iClass) = {tmpMVPA};
    end
    
    % save all tables together
    ACC_table = vertcat(mvpaCell{:});
    
end

% combine mvpa data with condition information
nRow = size(ACC_table, 1);
if ~nRow
    mvpa_table = table;
else
    mvpa_table = [repmat(uni_info, nRow, 1), ACC_table];
end

end
