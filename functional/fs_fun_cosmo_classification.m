function [mvpaTable, uniTable, uniLocTable] = fs_fun_cosmo_classification(project,...
    labelList, classPairs, classifiers, runLoc, outputPath)
% [mvpaTable, uniTable, uniLocTable] = fs_fun_cosmo_classification(project,...
%     labelList, classPairs, classifiers, outputPath)
% Inputs:
%    project             project structure (obtained from fs_fun_projectinfo)
%    labelList           a list of label names
%    classPairs          a list of pairs to be classified in MVPA
%    runLoc              run analyses for localizer scans
%    output_path         where output where be saved
% Outputs:
%    mvpaTable           MVPA result table (main runs)
%    uniTable            main run data for univariate analyses
%    uniLocTable         localizer run data for univariate analyses
%
% Created by Haiyang Jin (12-Dec-2019)

if nargin < 5 
    outputPath = '';
end

%% Preparation
% waitbar
waitHandle = waitbar(0, 'Loading...   0.00% finished');

% Project information (subject information)
sessList = project.sessList;
nSess = project.nSess;

% label information
if ischar(labelList)
    labelList = {labelList};
end
nLabel = numel(labelList);

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
            
            uniLocTableTemp = fs_fun_uni_cosmo_ds(project, ...
                thisLabel, thisSess, outputPath, runInfo, smooth, runSeparate);
            
            uniLocCell(iSess, iLabel) = {uniLocTableTemp};
        end
        
        
        %% Main runs (run separately)
        % get data for univariate and CoSMoMVPA
        runInfo = 'main';
        smooth = 0;
        runSeparate = 1;
                
        [uniMainTableTmp, ds_subj, uniInfo] = fs_fun_uni_cosmo_ds(project, ...
            thisLabel, thisSess, outputPath, runInfo, smooth, runSeparate);
        uniCell(iSess, iLabel) = {uniMainTableTmp};
        
        % run classification if ds_subj is not empty
        if ~isempty(ds_subj)
            mvpaTableTemp = fs_cosmo_classification(ds_subj, uniInfo, classPairs, classifiers);
        else
            mvpaTableTemp = table;
        end
        
        mvpaCell(iSess, iLabel) = {mvpaTableTemp};
        
    end
    
end
% waitbar
waitbar(progress, waitHandle, 'Saving data...');

% combine tables together
uniLocTable = vertcat(uniLocCell{:});
uniTable = vertcat(uniCell{:});
mvpaTable = vertcat(mvpaCell{:});

%% save data to local
if isempty(outputPath)
    outputPath = '.';
end
outputPath = fullfile(outputPath, 'Classification');
if ~exist(outputPath, 'dir'); mkdir(outputPath); end

% univariate analyses for localizers
if runLoc
    locUniFn = fullfile(outputPath, 'Localizer_Univariate');
    save(locUniFn, 'uniLocTable');
    writetable(uniLocTable, [locUniFn, '.xlsx']);
    writetable(uniLocTable, [locUniFn, '.csv']);
end

% MVPA for main runs
cosmoFn = fullfile(outputPath, 'Main_CosmoMVPA');
save(cosmoFn, 'mvpaTable');
mvpaTable(:, 'Confusion') = [];
writetable(mvpaTable, [cosmoFn, '.xlsx']);
writetable(mvpaTable, [cosmoFn, '.csv']);

% univariate for main runs
uniFn = fullfile(outputPath, 'Main_Univariate');
save(uniFn, 'uniTable');
writetable(uniTable, [uniFn, '.xlsx']);
writetable(uniTable, [uniFn, '.csv']);

close(waitHandle); % close the waitbar 

end