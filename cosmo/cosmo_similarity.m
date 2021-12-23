function [predTable, ds_out] = cosmo_similarity(ds, trainPairs, testCond, ...
    condWeight, dsInfo, autoscale)
% [predTable, ds_out] = cosmo_similarity(ds, classPairs, condName, ...
%   condWeight, dsInfo, autoscale)
%
% This function quantifies the similarity of the pattern to the two (or more)
% conditions in classPairs. The pattern could be another condition or the
% combination of multiple conditions (even with different weights).
%
% Inputs:
%    ds               <struct> data set for CoSMoMVPA.
%    trainPairs       <cell str> a 1xQ (usually is 2) cell vector for the 
%                      pairs to be trained on.
%    testCond         <cell str> a 1xR cell vector for the conditions to be
%                      tested. If R>1, the samples are combined with the 
%                      weights in [condWeight] for the similarity test.
%    condWeight       <array> a SxR numeric array for the weights to be
%                      applied to the combination of condName. Each row of 
%                      weights is tested on each [testCond] separately.
%    dsInfo           <struct> Extra information to be saved in mvpaTable. 
%                      E.g., the condition information obtained from
%                      fs_cosmo_subjds().
%    autoscale        <boo> scale the sample data before the combination. 
%                      Default is 1, i.e., z-scale data.
%
% Output:
%    predTable        <table> the prediction for the new condition and the
%                      related information.
%    ds_out           <struct> combined data set structure for the new 
%                      data and ds.
%
% Dependency:
%     CoSMoMVPA
%
% Created by Haiyang Jin (10-March-2020)

if isempty(ds) || isempty(ds.samples)
    predTable = table;
    ds_out = [];
    return;
end

% trainPairs needs to be a vector
if ~ismember(1, size(trainPairs)) && numel(trainPairs) ~= 1
    error('trainPairs needs to be a vector.');
end

% condName needs to be a vector
if ischar(testCond); testCond = {testCond}; end
testCond = testCond(:);
nCond = numel(testCond);

% The default weights are the average
if ~exist('condWeight', 'var') || isempty(condWeight)
    condWeight = repmat(1/nCond, 1, nCond);
end

if ~exist('dsInfo', 'var') || isempty(dsInfo)
    dsInfo = [];
end

% scale the data before combination by default
if ~exist('autoscale', 'var') || isempty(autoscale)
    autoscale = 1;
end

%% Calculate the similarity
% train data set
trainMask = cosmo_match(ds.sa.labels, trainPairs);

% quit if trainPairs is not available is in ds
if ~sum(trainMask)
    warning('Cannot find the classPairs in the data set.');
    predTable = table;
    ds_out = [];
    return;
else
    dt_train = cosmo_slice(ds, trainMask);
end

% test data sets before combinations
testMasks = cellfun(@(x) cosmo_match(ds.sa.labels, x), testCond, 'uni', false);
dts_test = cellfun(@(x) cosmo_slice(ds, x), testMasks, 'uni', true);

% Does the data need to be standarized before combinations?
if autoscale
    dts_test = arrayfun(@(x) cosmo_normalize(dts_test(x), 'zscore', 1),...
        1:numel(dts_test), 'uni', true);
    classopt.autoscale = 1;
else
    classopt.autoscale = 0;
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
    tempNames = vertcat(testCond, num2cell(thisWeight));
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
        dt_train.sa.targets, dt_test.samples, classopt);
    
    % save the results
    TrainPair = repmat(trainPairs, nRow, 1);
    Weights = repmat(thisWeight, nRow, 1);
    Combination = repmat({tempLabel}, nRow, 1);
    PredictCond = ds.sa.labels(PredictCode);
    outputCell(iWeight, 1) = {table(TrainPair, Combination, ...
        PredictCode, PredictCond, Probability, Weights)};
    
end

% save ds in the dtCell
dsCell(nWeight+1, 1) = {ds};

% convert cell to table
predTable = vertcat(outputCell{:});
ds_out = cosmo_stack(dsCell);

% combine mvpa data with condition information
nRow = size(predTable, 1);
if ~nRow || isempty(dsInfo)
    predTable = table;
else
    predTable = [repmat(dsInfo, nRow, 1), predTable];
end

end