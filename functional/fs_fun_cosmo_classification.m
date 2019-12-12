function [mvpaTable, uniTable, uniLocTable] = fs_fun_cosmo_classification(projStr,...
    labelList, classPairs, classifiers, runLoc, output_path)
% [mvpaTable, uniTable, uniLocTable] = fs_fun_cosmo_classification(projStr,...
%     labelList, classPairs, classifiers, output_path)
% Inputs:
%    projStr             project structure (e.g., fw_projectinfo.m)
%    labelList           a list of label names
%    classPairs          a list of pairs to be classified in MVPA
%    runLoc              run analyses for localizer scans
%    output_path         where output where be saved
% Outputs:
%    mvpaTable           MVPA result table (main runs)
%    uniTable            main run data for univariate analyses
%    uniLocTable         localizer run data for univariate analyses
%
% Created by Haiyang Jin (12/12/2019)

if nargin < 5 
    output_path = '';
end

%% Preparation
% waitbar
wait_f = waitbar(0, 'Loading...   0.00% finished');

% Project information (subject information)
subjList = projStr.subjList;
nSubj = projStr.nSubj;

% label information
if ischar(labelList)
    labelList = {labelList};
end
nLabel = numel(labelList);

% create empty table
uniLocCell = cell(nSubj, nLabel);
uniCell = cell(nSubj, nLabel);
mvpaCell = cell(nSubj, nLabel);

for iSubj = 1:nSubj
    
    % this subject code (bold)
    thisSubjBold = subjList{iSubj};
    
    for iLabel = 1:nLabel
        
        % this label
        thisLabel = labelList{iLabel};
        
        % waitbar
        progress = ((iLabel-1)*nSubj + iSubj) / (nLabel * nSubj);
        progress_msg = sprintf('Label: %s.  Subject: %s \n%0.2f%% finished...', ...
            thisLabel, strrep(thisSubjBold, '_', '\_'), progress*100);
        waitbar(progress, wait_f, progress_msg);
        
        %% Localizer
        if runLoc
            run_info = 'loc';
            smooth = '';
            runSeparate = 0;
            
            uniLocTable_tmp = fs_fun_uni_cosmo_ds(projStr, ...
                thisLabel, thisSubjBold, output_path, run_info, smooth, runSeparate);
            
            uniLocCell(iSubj, iLabel) = {uniLocTable_tmp};
        end
        
        
        %% Main runs (run separately)
        % get data for univariate and CoSMoMVPA
        run_info = 'main';
        smooth = 0;
        runSeparate = 1;
                
        [uniMainTable_tmp, ds_subj, uni_info] = fs_fun_uni_cosmo_ds(projStr, ...
            thisLabel, thisSubjBold, output_path, run_info, smooth, runSeparate);
        uniCell(iSubj, iLabel) = {uniMainTable_tmp};
        
        % run classification if ds_subj is not empty
        if ~isempty(ds_subj)
            mvpaTable_tmp = fs_cosmo_classification(ds_subj, uni_info, classPairs, classifiers);
        else
            mvpaTable_tmp = table;
        end
        
        mvpaCell(iSubj, iLabel) = {mvpaTable_tmp};
        
    end
    
end
% waitbar
waitbar(progress, wait_f, 'Saving data...');

% combine tables together
uniLocTable = vertcat(uniLocCell{:});
uniTable = vertcat(uniCell{:});
mvpaTable = vertcat(mvpaCell{:});

%% save data to local
if isempty(output_path)
    output_path = '.';
end
output_path = fullfile(output_path, 'Classification');
if ~exist(output_path, 'dir'); mkdir(output_path); end

% univariate analyses for localizers
if runLoc
    fn_locuni = fullfile(output_path, 'Localizer_Univariate');
    save(fn_locuni, 'uniLocTable');
    writetable(uniLocTable, [fn_locuni, '.xlsx']);
    writetable(uniLocTable, [fn_locuni, '.csv']);
end

% MVPA for main runs
fn_cosmo = fullfile(output_path, 'Main_CosmoMVPA');
save(fn_cosmo, 'mvpaTable');
mvpaTable(:, 'Confusion') = [];
writetable(mvpaTable, [fn_cosmo, '.xlsx']);
writetable(mvpaTable, [fn_cosmo, '.csv']);

% univariate for main runs
fn_uni = fullfile(output_path, 'Main_Univariate');
save(fn_uni, 'uniTable');
writetable(uniTable, [fn_uni, '.xlsx']);
writetable(uniTable, [fn_uni, '.csv']);

close(wait_f); % close the waitbar 

end