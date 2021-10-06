function [status, hcpcmd, specFile] = hcp_viewcon(subjCode, runinfo, isNative)
% [status, hcpcmd, specFile] = hcp_viewcon(subjCode, runinfo, isNative)
%
% This function visualizes functional data analyzed on 'fsaverage_LR32k'.
% this function mainly supports results for level 1 and 2 (may support
% level 3 later).
%
% level 1 results: for single subject and single run;
% level 2 results: for single subject across runs;
% level 3 results: across subjects and runs (to be added).
%
% Inputs:
%    subjCode         <str> subject code.
%    runinfo          <cell string> list of run folders. more see hcp_runlist.
%                  or <string> string pattern (wildcard) to match run folders.
%    isNative         <str> whether to display the native structure;
%                      default is 1.
%
% Outputs:
%    status           <int array> the status of running cmds. Only 0
%                      suggests that the commands completed successfully.
%    hcpcmd           <str> the hcp command.
%    specFile         <str> full path to the *.wb.spec file.
%
% % Example 1:
% [status, hcpcmd, specFile] = hcp_viewcon(subjCode, 'tfMRI_*_PA');
%
% % Example 2:
% [status, hcpcmd, specFile] = hcp_viewcon(subjCode, 'level2*');
%
% % Example 3: visualize results in all folders (both level1 and level2)
% [status, hcpcmd, specFile] = hcp_viewcon(subjCode, '*');
%
% Created by Haiyang Jin (2021-10-06)

% setup
if ~exist('runinfo', 'var') || isempty(runinfo)
    error('Please set "runinfo" as a list of run folder names.');
end

if ~exist('isNative', 'var') || isempty(isNative)
    isNative = 1;
end
templates = {'MNINonLinear', 'T1w'};
template = fullfile(templates{isNative+1}, 'fsaverage_LR32k');

% run information
[runlist, nRun] = hcp_runlist(subjCode, runinfo);

filecell = cell(nRun, 1);

% read files for each run separately
for iRun = 1:nRun
    
    runfolder = runlist{iRun};
    
    if startsWith(runfolder, 'level2')
        % identify feat dir, cope and zstat files
        featdir = dir(fullfile(hcp_funcdir(subjCode), runfolder, 'level2*level2.feat'));
        copedir = dir(fullfile(featdir.folder, featdir.name, '*level2_cope_hp200_s2.*dscalar.nii'));
        zstatdir = dir(fullfile(featdir.folder, featdir.name, '*level2_zstat_hp200_s2.*dscalar.nii'));
        alldir = [copedir; zstatdir];
        
    else % for level 1 results
        % find the folder name ending with *.feat
        featdir = dir(fullfile(hcp_funcdir(subjCode), runfolder, '*fMRI*level1.feat'));
        alldir = dir(fullfile(featdir.folder, featdir.name, 'GrayordinatesStats', 'all*dscalar.nii'));
    end
    
    % save the result files
    filecell{iRun, 1} = fullfile({alldir.folder}, {alldir.name});
    
end
% convert into a cell vector
fileList = horzcat(filecell{:});

% print all the files to be displayed
fprintf('\nThese files will be displayed (%d): \n%s', ...
    length(fileList), sprintf('%s \n', fileList{:}));

% make and run wb_view cmd
[status, hcpcmd, specFile] = hcp_view(subjCode, template, '', fileList);

end