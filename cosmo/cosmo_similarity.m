function [predictTable, ds_out] = cosmo_similarity(ds, classPairs, condName, condWeight, autoscale)
% [predictTable, ds_combined] = cosmo_similarity(ds, classPairs, condName, condWeight, autoscale)
%
% This function quantifies the similarity of the pattern to the two (or more)
% conditions in classPairs. The pattern could be another condition or the
% combination of multiple conditions (even with different weights).
%
% Inputs:
%    ds               <structure> data set for CoSMoMVPA.
%    classPairs       <cell of strings> a 1xQ (usually is 2) cell vector
%                      for the pairs to be classified.
%    condName         <cell of strings> a 1xQ cell vector for the 
%                      conditions to be combined for the similarity test.
%    condWeight       <array of numeric> a PxQ numeric array for the
%                      weights to be applied to the combination of condName.
%                      Each row of weights is tested separately.
%    autoscale        <logical> scale the sample data before the
%                      combination. Default is Z scale data.
%
% Output:
%    predictTable     <table> the prediction for the new condition and the
%                      related information.
%    ds_out           <structure> combined data set structure for the new 
%                      data and ds.
%
% Dependency:
%     CoSMoMVPA
%
% Created by Haiyang Jin (10-March-2020)

% classPairs needs to be a vector
if ~ismember(1, size(classPairs)) && numel(classPairs) ~= 1
    error('classPairs needs to be a vector.');
end

% condName needs to be a vector
if ~ismember(1, size(condName)) && numel(classPairs) ~= 1
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
    error('The column number of conWeight should equal to the length of condName.');
end

% scale the data before combination by default
if nargin < 5 || isempty(autosacle)
    autoscale = 1;
end

%% Calculate the similarity
% train data set
trainMask = cosmo_match(ds.sa.labels, classPairs);

% quit if classPair is not available is in ds
if ~sum(trainMask)
    warning('Cannot find the classPairs in the data set.');
    predictTable = [];
    ds_out = [];
    return;
else
    dt_train = cosmo_slice(ds, trainMask);
end

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
dsCell = cell(nWeight+1, 1);

target = max(ds.sa.targets);

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
    target = target + 1;
    dt_test.sa.targets = repmat(target, nRow, 1);
    
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
    outputCell(iWeight, 1) = {table(ClassPair, Combination, ...
        PredictCode, PredictCond, Probability, Weights)};
    
end

% save ds in the dtCell
dsCell(nWeight+1, 1) = {ds};

% convert cell to table
predictTable = vertcat(outputCell{:});
ds_out = cosmo_stack(dsCell);

end