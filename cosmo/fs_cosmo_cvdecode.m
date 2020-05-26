function [mvpaTable, uniTable, uniLocTable] = fs_cosmo_cvdecode(sessList,...
    labelList, classPairs, runLoc, template, outPath, classifiers, funcPath)
% [mvpaTable, uniTable, uniLocTable] = fs_cosmo_cvdecode(sessList,...
%    labelList, classPairs, runLoc, template, outputPath, classifiers, funcPath)
%
% This function run the cross-validation classification (decoding) for all
% subjects and all pairs.
%
% Inputs:
%    sessList           <cell of string> session code in functional folder.
%    labelList          <cell of strings> a list of label names.
%    classPairs         <cell of strings> a PxQ (usually is 2) cell matrix 
%                         for the pairs to be classified. Each row is one 
%                         classfication pair. 
%    runLoc             <logical> run analyses for localizer scans.
%    template           <string> 'fsaverage' or 'self'. fsaverage is the default.
%    outPath            <string> where output to be saved.
%    classifiers        <numeric> or <strings> or <cells> the classifiers 
%                         to be used (only 1).
%
% Outputs:
%    mvpaTable          <table> MVPA result table (main runs).
%    uniTable           <table> main run data for univariate analyses.
%    uniLocTable        <table> localizer run data for univariate analyses.
%
% Created by Haiyang Jin (12-Dec-2019)

if nargin < 5 || isempty(template)
    template = '';
end

if nargin < 4 || isempty(runLoc)
    runLoc = 0;
    warning('Classification (decoding) only performs on main runs by default.');
end

if nargin < 6 
    outPath = '';
end

if ~exist('classifiers', 'var') || isempty(classifiers)
    classifiers = [];
end

if ~exist('funcPath', 'var') || isempty(funcPath)
    funcPath = getenv('FUNCTIONALS_DIR');
end

%% Preparation
% waitbar
waitHandle = waitbar(0, 'Loading...   0.00% finished');

% session codes
if ischar(sessList)
    sessList = {sessList};
end
nSess = numel(sessList);

% label information
if ischar(labelList)
    labelList = {labelList};
end
nLabel = numel(labelList);

%% Crossvalidation decode
% create empty table
uniLocCell = cell(nSess, nLabel);
uniCell = cell(nSess, nLabel);
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
        
        %% Localizer
        if runLoc
            runInfo = 'loc';
            smooth = '';
            runSeparate = 0;
            
            [locDsTemp, condInfoTemp] = fs_cosmo_subjds(thisSess, ...
                thisLabel, template, '', runInfo, smooth, runSeparate);
            
            uniLocTableTemp = fs_ds2uni(locDsTemp, condInfoTemp);
            uniLocCell(iSess, iLabel) = {uniLocTableTemp};
        end
        
        %% Main runs (run separately)
        % get data for univariate and CoSMoMVPA
        runInfo = 'main';
        smooth = 0;
        runSeparate = 1;
                
        [ds_subj, condInfo] = fs_cosmo_subjds(thisSess, ...
            thisLabel, template, funcPath, runInfo, smooth, runSeparate);
        
        % add more inforamtion about this label
%         tempTable = fs_labelinfo(thisLabel, fs_subjcode(thisSess));
%         condInfo = horzcat(condInfo, tempTable);
       
        % run classification if ds_subj is not empty
        if ~isempty(ds_subj)
            mvpaTableTemp = cosmo_cvdecode(ds_subj, classPairs, condInfo, classifiers);
            % convert ds to uniTable
            uniMainTableTmp = fs_ds2uni(ds_subj, condInfo);
        else
            mvpaTableTemp = table;
            uniMainTableTmp = table;
        end
        
        mvpaCell(iSess, iLabel) = {mvpaTableTemp};
        uniCell(iSess, iLabel) = {uniMainTableTmp};
        
    end
    
end
% waitbar
waitbar(progress, waitHandle, 'Saving data...');

% combine tables together
uniLocTable = vertcat(uniLocCell{:});
uniTable = vertcat(uniCell{:});
mvpaTable = vertcat(mvpaCell{:});

%% save data to local
if isempty(outPath)
    outPath = '.';
end
outPath = fullfile(outPath, 'Classification');
if ~exist(outPath, 'dir'); mkdir(outPath); end

% univariate analyses for localizers
if runLoc
    locUniFn = fullfile(outPath, 'Localizer_Univariate');
    save(locUniFn, 'uniLocTable');
    writetable(uniLocTable, [locUniFn, '.xlsx']);
    writetable(uniLocTable, [locUniFn, '.csv']);
end

% MVPA for main runs
cosmoFn = fullfile(outPath, 'Main_CosmoMVPA');
save(cosmoFn, 'mvpaTable');
mvpaTable(:, 'Confusion') = [];
writetable(mvpaTable, [cosmoFn, '.xlsx']);
writetable(mvpaTable, [cosmoFn, '.csv']);

% univariate for main runs
uniFn = fullfile(outPath, 'Main_Univariate');
save(uniFn, 'uniTable');
writetable(uniTable, [uniFn, '.xlsx']);
writetable(uniTable, [uniFn, '.csv']);

close(waitHandle); % close the waitbar 

end