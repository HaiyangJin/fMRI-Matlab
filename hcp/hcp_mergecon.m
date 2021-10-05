function [status, cmdlist] = hcp_mergecon(subjCode, runinfo, coninfo, runcmd)
% [status, cmdlist] = hcp_mergecon(subjCode, runinfo, coninfo, runcmd)
%
% This function merges all the contrast files (<coninfo>) for level1
% results and convert the merged file to a cifti scalar file. The final
% output file is useful for visualization purpose in HCP workbench. [There
% is no need to use this function to process the level2 results as the
% merged scalar files are already available.]
%
% Inputs:
%    subjCode      <string> subject code.
%    runinfo       <cell string> list of run folders.
%               or <string> string pattern (wildcard) to match run folders.
%    coninfo       <str> string pattern (wildcard) to match the functional
%                   output filenames (mainly contrast files). Default is
%                   {'cope*.dtseries.nii', 'tstat*.dtseries.nii',
%                   'zstat*.dtseries.nii'}.
%    runcmd        <logic> whether run the hcp commands (default is 1).
%
% Outputs:
%    status        <num array> the status of running cmds. Only 0 suggests
%                   that the commands completed successfully.
%    cmdlist       <cell str> the hcp commands.
%
% % Example 1:
% hcp_merge('subjcode'); % need to set hcp project path first
%
% Created by Haiyang Jin (2021-10-05)

% setup
if ~exist('runinfo', 'var') || isempty(runinfo)
    runinfo = 'tfMRI*';
    warning('"%s" is used as runinfo by default.', runinfo);
end

if ~exist('coninfo', 'var') || isempty(coninfo)
    coninfo = {'cope*.dtseries.nii', 'tstat*.dtseries.nii', 'zstat*.dtseries.nii'};
end
nFunc = length(coninfo);

if ~exist('runcmd', 'var') || isempty(runcmd)
    runcmd = 1;
end

% get the functional data directory
funcdir = hcp_funcdir(subjCode);

% get the run list
if ischar(runinfo)
    rundir = dir(fullfile(funcdir, runinfo));
    runlist = {rundir.name};
elseif iscell(runinfo)
    runlist = runinfo;
end
nRun = length(runlist);
cmdcell = cell(nRun, nFunc, 2);  % 2 is for two hcp commands

%% read dt for each folder (or run) separately
for iRun = 1:nRun
    
    runfolder = runlist{iRun};
    
    % find the folder name ending with *.feat
    featdir = dir(fullfile(funcdir, runfolder, [runfolder '*.feat']));
    featPath = fullfile(funcdir, runfolder, featdir.name, 'GrayordinatesStats');
    
    % read contrast information (level1)
    condir = dir(fullfile(funcdir, runfolder, featdir.name, 'design.con'));
    conList = hcp_readcon(fullfile(condir.folder, condir.name)); % contrast list
    
    % save contrast names as contrasts_merge.txt
    con_merge_fn = fullfile(featPath, 'contrasts_merge.txt');
    fm_createfile(con_merge_fn, conList);
    
    % merge for each file type
    for iFunc = 1:nFunc
        
        % get the file list
        theDir = dir(fullfile(featPath, coninfo{iFunc}));
        theList = {theDir.name};
        
        % sort the file list
        [~, theOrder] = sort(cellfun(@(x) str2double(regexp(x,'\d*','Match')), theList));
        theList = theList(theOrder);
        
        % remove numbers
        outcell = unique(cellfun(@(x) regexprep(x, '\d', ''), theList, 'uni', false));
        % get the unique file name
        assert(numel(outcell) == 1, ['Failed to identify the unique output filename.',...
            '\nThe unique names are: \n%s.'], sprintf('%s ',outcell{:}))
        
        % full file list
        theFullList = fullfile(featPath, theList);
        
        % create the cmd list for -cifti-merge
        mergedFn = fullfile(featPath, ['all', outcell{1}]);
        hcpcmd_merge = sprintf(['wb_command -cifti-merge %s -cifti %s', ...
            repmat(' -cifti %s', 1, numel(theList)-1)], ...
            mergedFn, theFullList{:});
        
        cmdcell{iRun, iFunc, 1} = hcpcmd_merge;
        
        % create the cmd list for -cifti-change-mapping
        hcpcmd_change = sprintf(['wb_command -cifti-change-mapping %s ROW ', ...
            '%s -scalar -name-file %s'], mergedFn, ...
            strrep(mergedFn, 'dtseries.nii', 'dscalar.nii'), con_merge_fn);
        
        cmdcell{iRun, iFunc, 2} = hcpcmd_change;
    end
end

% deal with space in cmd
cmdcell = fm_cleancmd(cmdcell);

% run the hcp commands
if runcmd
    statuscell = cellfun(@system, cmdcell, 'uni', false);
    status = cell2mat(statuscell);
else
    status = 0;
end

% make sure codes completed successfully
assert(~any(status, 'all'), 'Some of the hcp commands failed for hcp_merge.');

cmdlist = vertcat(cmdcell(:));

end