function [predictTable, ds_combined] = cosmo_similarity(ds, classPairs, condName, condWeight, autoscale)
% [predictTable, ds_combined] = cosmo_similarity(ds, classPairs, condName, condWeight, autoscale)
%
% This function quantifies the similarity of the pattern to the two (or more)
% conditions in classPairs. The pattern could be another condition or the
% combination of multiple conditions (even with different weights).
%
% Inputs:
%     ds               <structure> data set for CoSMoMVPA.
%     classPairs       <cell of strings> a 1xQ (usually is 2) cell vector
%                      for the pairs to be classified.
%     condName         <cell of strings> a 1xQ (usually is 2) cell vector
%                      the conditions to be combined for the similarity test.
%     condWeight       <array of numeric> a PxQ numeric array for the
%                      weights to be applied to the combination of condName.
%                      Each row is for one similarity test
%     autoscale        <logical> scale the sample data before the
%                      combination. Default is Z scale data.
%
% Output:
%     predictTable     <table> the prediction for the new condition and the
%                      related information.
%     ds_combined      <structure> data set structure for the combined
%                      data.
%
% Dependency:
%     CoSMoMVPA
%
% Created by Haiyang Jin (10-March-2020)

% classPairs needs to be a vector
if ~ismember(1, size(classPairs))
    error('classPairs needs to be a vector.');
end

% condName needs to be a vector
if ~ismember(1, size(condName))
    error('condName needs to be a vector.');
elseif size(condName, 1) ~= 1
    condName = transpose(condName);
end
nCond = numel(condName);

% The default weights are the average
if nargin < 4 || isempty(condWeight)
    condWeight = repmat(1/nCond, 1, nCond);
end

% The length of condName and condWeight should be the same
if nCond ~= size(condWeight, 2)
    error('The column number of conWeight should be equal to the length of condName.');
end

% scale the data before combination by default
if nargin < 5 || isempty(autosacle)
    autoscale = 1;
end

%% Calculate the similarity
% train data set
trainMask = cosmo_match(ds.sa.labels, classPairs);
dt_train = cosmo_slice(ds, trainMask);

% test data sets before combinations
testMasks = cellfun(@(x) cosmo_match(ds.sa.labels, x), condName, 'uni', false);
dts_test = cellfun(@(x) cosmo_slice(ds, x), testMasks, 'uni', true);

% Does the data need to be standarized before combinations?
if autoscale
    dts_test = arrayfun(@(x) cosmo_normalize(dts_test(x), 'zscore', 1),...
        1:numel(dts_test), 'uni', true);
end

nRow = size(dts_test(1).samples, 1);

% empty varaibles for saving results
nWeight = size(condWeight, 1);
outputCell = cell(nWeight, 1);
dsCell = cell(nWeight, 1);

% run the test for each weights separately
for iWeight = 1:nWeight
    
    dt_test = dts_test(1);
    
    % the weight for this anlaysis
    thisWeight = condWeight(iWeight, :);
    
    % create the label name for this weight
    tempNames = vertcat(condName, num2cell(thisWeight));
    tempLabel = sprintf(['%s%1.2f' repmat('-%s%1.2f', 1, nCond-1)], tempNames{:});
    
    % "Standarize" the weights if the sum is not 1
    if sum(thisWeight) ~= 1
        warning('The Weight (iWeight=%d) is standarized now...', iWeight);
        thisWeight = thisWeight / sum(thisWeight);
    end
    
    % combine the test data sets
    tempSamples = arrayfun(@(x, y) dts_test(x).samples * y, 1:numel(dts_test),...
        thisWeight, 'uni', false);
    
    % samples
    dt_test.samples = sum(cat(3, tempSamples{:}), 3);
    % sample attributes (labels)
    dt_test.sa.labels = repmat({tempLabel}, nRow, 1);
    dt_test.sa.targets = zeros(nRow, 1);
    
    % save the dataset
    dsCell(iWeight, 1) = {dt_test};
    
    %%%%%%%%%%%%%%%%%%%%%% train and predict data %%%%%%%%%%%%%%%%%%%%%%%%%
    [PredictCode, Probability] = cosmo_classify_libsvm_p(dt_train.samples,...
        dt_train.sa.targets, dt_test.samples);
    
    % save the results
    ClassPair = repmat(classPairs, nRow, 1);
    Weights = repmat(thisWeight, nRow, 1);
    Combination = repmat({tempLabel}, nRow, 1);
    PredictCond = ds.sa.labels(PredictCode);
    outputCell(iWeight, 1) = {table(ClassPair, Combination, Weights, ...
        PredictCode, PredictCond, Probability)};
    
end

% convert cell to table
predictTable = vertcat(outputCell{:});
ds_combined = cosmo_stack(dsCell);

end