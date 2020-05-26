function mvpaTable = fs_cosmo_cvdecode(sessList, anaList, labelList, runList, ...
    classPairs, outPath, classifiers)
% mvpaTable = fs_cosmo_cvdecode(sessList, anaList, labelList, runList, ...
%   classPairs, outPath, classifiers)
%
% This function run the cross-validation classification (decoding) for all
% subjects and all pairs.
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
%                    for the pairs to be classified. Each row is one
%                     classfication pair.
%    outPath         <string> where output to be saved.
%    classifiers     <numeric> or <strings> or <cells> the classifiers
%                         to be used (only 1).
%
% Outputs:
%    mvpaTable          <table> MVPA result table (main runs).
%
% Created by Haiyang Jin (12-Dec-2019)

%% Deal with inputs
% waitbar
waitHandle = waitbar(0, 'Loading...   0.00% finished');

if ischar(sessList); sessList = {sessList}; end
nSess = numel(sessList);
if ischar(anaList); anaList = {anaList}; end
if ischar(labelList); labelList = {labelList}; end
nLabel = numel(labelList);

if ~exist('outPath', 'var') || isempty(outPath)
    outPath = '';
end
if ~exist('classifiers', 'var') || isempty(classifiers)
    classifiers = [];
end

%% Cross validation decode
% create empty table
mvpaCell = cell(nSess, nLabel);

for iSess = 1:nSess
    
    % this subject code (bold)
    thisSess = sessList{iSess};
    
    for iLabel = 1:nLabel
        
        % this label
        thisLabel = labelList{iLabel};
        
        % waitbar
        progress = ((iSess-1)*nLabel + iLabel) / (nLabel * nSess);
        progressMsg = sprintf('Label: %s.  Subject: %s \n%0.2f%% finished...', ...
            thisLabel, strrep(thisSess, '_', '\_'), progress*100);
        waitbar(progress, waitHandle, progressMsg);
        
        % get the corresponding analysis name
        isAna = contains(anaList, fs_2hemi(thisLabel));
        theAna = anaList(isAna);
        
        % get data for CoSMoMVPA
        [ds_subj, condInfo] = cellfun(@(x) fs_cosmo_sessds(thisSess, x, ...
            'labelfn', thisLabel, 'runlist', runList, 'runwise', 1), ...
            theAna, 'uni', false);
        
        tempCell = cellfun(@(x, y) cosmo_cvdecode(x, classPairs, y, classifiers),...
            ds_subj, condInfo, 'uni', false);
        
        % run classification
        mvpaCell{iSess, iLabel} = vertcat(tempCell{:});
    end
    
end
% waitbar
waitbar(progress, waitHandle, 'Saving data...');

% combine tables together
mvpaTable = vertcat(mvpaCell{:});

%% save data to local
if isempty(outPath)
    outPath = fullfile(pwd, 'Classification');
end
if ~exist(outPath, 'dir'); mkdir(outPath); end

% MVPA for main runs
cosmoFn = fullfile(outPath, 'Main_CosmoMVPA');
save(cosmoFn, 'mvpaTable');
mvpaTable(:, 'Confusion') = [];
writetable(mvpaTable, [cosmoFn, '.xlsx']);
writetable(mvpaTable, [cosmoFn, '.csv']);

close(waitHandle); % close the waitbar

end