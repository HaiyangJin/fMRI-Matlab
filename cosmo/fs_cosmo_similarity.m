function predTable = fs_cosmo_similarity(sessList, anaList, labelList, runInfo, ...
    trainPairs, testCond, testWeight, autoscale, outPath)
% predTable = fs_cosmo_similarity(sessList, anaList, labelList, runInfo, ...
%    trainPairs, testWeight, condWeight, autoscale, outPath)
%
% This function decodes the similarity of condName to classPairs for all
% the sessions in the project. libsvm is used in this analysis.
%
% Inputs:
%    sessList        <cell str> a list of session codes.
%    anaList         <cell str> a list of analysis names.
%    labelList       <cell str> a list of label names.
%    runInfo         <str> the filename of the run file (e.g.,
%                     run_loc.txt.) [Default is '' and then names of
%                     all run folders will be used.]
%                OR  <cell str> a list of all the run names. (e.g.,
%                     {'001', '002', '003'....}.
%    trainPairs      <cell str> a PxQ (usually is 2) cell matrix 
%                     for the pairs to be trained. Each row is one 
%                     classfication (train) pair. 
%    testCond        <cell str> a PxR cell vector for the conditions to be
%                     tested. Each row will be combined with the weights in 
%                     [condWeight] for the similarity test. E.g., if R is
%                     1, the sample will be tested directly. The row number
%                     should be same as that for classPairs (i.e., P).
%                     The similarity of [testCond] to classPairs will be
%                     tested for each row separatedly.
%    testWeight      <num array> a SxR numeric array for the
%                     weights to be applied to the combination of condName.
%                     Each row of weights is tested separately. Default is
%                     the mean of each row. If [conWeight] is -1, each of
%                     the test conditions (in each row) will be test 
%                     separately with the classifier trained with 
%                     [trainPairs] on that row. No combination will be
%                     performed.
%    autoscale       <boo> whether apply autoscale to train and test
%                     datasets. Default is 1.
%    outPath         <str> where output to be saved.
%
% Output:
%    predTable       <table> the prediction for the new condition and 
%                     the related information.
%
% Dependencies:
%    FreeSurfer matlab functions;
%    CoSMoMVPA
%
% Created by Haiyang Jin (11-March-2020)

%% Deal with inputs
% waitbar
waitHandle = waitbar(0, 'Loading...   0.00% finished');

if ischar(sessList); sessList = {sessList}; end
nSess = numel(sessList);
if ischar(anaList); anaList = {anaList}; end
if ischar(labelList); labelList = {labelList}; end
nLabel = numel(labelList);

% The row numbers of classPairs and condName have to be the same.
nClass = size(trainPairs, 1);
assert(nClass == size(testCond, 1), ...
    'The row numbers of classPairs and condName should be the same.');

if ~exist('testWeight', 'var') || isempty(testWeight)
    testWeight = [];
end

if ~exist('autoscale', 'var') || isempty(autoscale)
    autoscale = 1;
end

if ~exist('outPath', 'var') || isempty(outPath)
    outPath = '';
end

%% Run cosmo_similarity
% empty cell for saving prediction table
predCell = cell(nSess, nLabel);

for iSess = 1:nSess
    
    % this session code
    thisSess = sessList{iSess};
    
    for iLabel = 1:nLabel
        
        % this label name
        thisLabel = labelList{iLabel};
        
        % waitbar
        progress = ((iSess-1)*nLabel + iLabel) / (nLabel * nSess);
        progressMsg = sprintf('Label: %s.  Subject: %s \n%0.2f%% finished...', ...
            thisLabel, strrep(thisSess, '_', '\_'), progress*100);
        waitbar(progress, waitHandle, progressMsg);
        
        % get the corresponding analysis name
        isAna = contains(anaList, fm_2hemi(thisLabel));
        theAna = anaList(isAna);
        assert(numel(theAna) == 1, ['Please make sure there is only one' ...
            ' analysis name for each hemisphere']);
        
        % load the data set
        [ds_subj, dsInfo] = fs_cosmo_sessds(thisSess, theAna{1}, ...
            'labelfn', thisLabel, 'runinfo', runInfo, 'runwise', 1);
        
        if numel(testWeight)==1 && testWeight==-1
            %%%%%%%%%% estimate the similarity (without combination) %%%%%%%%%%
            simiCell = cell(size(trainPairs, 1), 1);
            
            for iTrain = 1:size(trainPairs, 1)

                tmpTestC = testCond{iTrain};

                tmpSimiCell = cellfun(@(x) cosmo_similarity(ds_subj, ...
                    trainPairs(iTrain, :), x, 1, dsInfo, autoscale), ...
                    tmpTestC(:), 'uni', false);

                simiCell{iTrain, 1} = vertcat(tmpSimiCell{:});
            end

        else
            %%%%%%%%%% estimate the similarity (with combination) %%%%%%%%%%
            simiCell = arrayfun(@(x) cosmo_similarity(ds_subj, ...
                trainPairs(x, :), testCond(x, :), testWeight, dsInfo, autoscale), ...
                1:nClass, 'uni', false);
        end

        predCell{iSess, iLabel} = vertcat(simiCell{:});
    
    end
end

%% Save the output
% waitbar
waitbar(progress, waitHandle, 'Saving data...');

% obtain the predictTable
predTable = vertcat(predCell{:});

% the path
if isempty(outPath)
    outPath = fullfile(pwd, 'Classification');
end
if ~exist(outPath, 'dir'); mkdir(outPath); end

% the filename
similarityFn = fullfile(outPath, 'Main_Similarity');
save(similarityFn, 'predTable');

writetable(predTable, [similarityFn, '.xlsx']);
writetable(predTable, [similarityFn, '.csv']);

% close the waitbar 
close(waitHandle); 

end