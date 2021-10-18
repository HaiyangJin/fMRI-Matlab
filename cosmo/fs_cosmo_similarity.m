function predTable = fs_cosmo_similarity(sessList, anaList, labelList, runList, ...
    classPairs, condName, condWeight, autoscale, outPath)
% predTable = fs_cosmo_similarity(sessList, anaList, labelList, runList, ...
%    classPairs, condName, condWeight, autoscale, outPath)
%
% This function decodes the similarity of condName to classPairs for all
% the sessions in the project. libsvm is used in this analysis.
%
% Inputs:
%    sessList        <cell string> a list of session codes.
%    anaList         <cell string> a list of analysis names.
%    labelList       <cell string> a list of label names.
%    runList         <string> the filename of the run file (e.g.,
%                     run_loc.txt.) [Default is '' and then names of
%                     all run folders will be used.]
%                OR  <string cell> a list of all the run names. (e.g.,
%                     {'001', '002', '003'....}.
%    classPairs      <cell string> a PxQ (usually is 2) cell matrix 
%                     for the pairs to be classified. Each row is one 
%                     classfication pair. 
%    condName        <cell string> a PxQ cell vector for the 
%                     conditions to be combined for the similarity test.
%                     The row number should be same as that for classPairs.
%                     The similarity of condName to classPairs will be
%                     tested separated for each row.
%    condWeight      <numeric array> a PxQ numeric array for the
%                     weights to be applied to the combination of condName.
%                     Each row of weights is tested separately.
%    autoscale       <logical> whether apply autoscale to train and test
%                     datasets. Default is 1.
%    outPath         <string> where output to be saved.
%
% Output:
%    predTable        <table> the prediction for the new condition and 
%                      the related information.
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
nClass = size(classPairs, 1);
assert(nClass == size(condName, 1), ...
    'The row numbers of classPairs and condName should be the same.');

if ~exist('condWeight', 'var') || isempty(condWeight)
    condWeight = '';
elseif size(condWeight, 2) ~= size(condName, 2)
    error('The column numbers of condWeight and condName should be the same.');
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
            'labelfn', thisLabel, 'runlist', runList, 'runwise', 1);
        
        %%%%%%%%%%%%%%% estimate the similarity %%%%%%%%%%%%%%%%%%
        simiCell = arrayfun(@(x, y) cosmo_similarity(ds_subj, ...
            classPairs(x, :), condName(x, :), condWeight, dsInfo, autoscale), ...
            1:nClass, 'uni', false);
        
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