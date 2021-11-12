function [status, cmdlist] = hcp_mergecon(subjCode, runinfo, coninfo, modality, runcmd)
% [status, cmdlist] = hcp_mergecon(subjCode, runinfo, coninfo, runcmd)
%
% This function merges all the contrast files (<coninfo>) for level1
% results and convert the merged file to a cifti scalar file. The final
% output file is useful for visualization purpose in HCP workbench. [There
% is no need to use this function to process the level2 results as the
% merged scalar files are already available.]
%
% Inputs:
%    subjCode      <str> subject code.
%    runinfo       <cell str> list of run folders. more see hcp_runlist.
%               or <str> string pattern (wildcard) to match run folders.
%    coninfo       <str> string pattern (wildcard) to match the functional
%                   output filenames (mainly contrast files). Default is
%                   {'cope*', 'tstat*', 'zstat*'}.
%    modality      <int> 1: data on surface (cifti); 2: data in volume
%                   (nifti); default is [1,2];
%    runcmd        <boo> whether run the hcp commands (default is 1).
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
    coninfo = {'cope*', 'tstat*', 'zstat*'};
end
nFunc = length(coninfo);

if ~exist('modality', 'var') || isempty(modality)
    modality = [1,2];
end
resultcell = {'GrayordinatesStats', 'StandardVolumeStats'};

if ~exist('runcmd', 'var') || isempty(runcmd)
    runcmd = 1;
end

% get the functional data directory
funcdir = hcp_funcdir(subjCode);

% get the run list
[runlist, nRun] = hcp_runlist(subjCode, runinfo);

cmdcell = cell(nRun, nFunc, length(modality));  % the last is for cifti and nifti

%% read dt for each folder (or run) separately
for iRun = 1:nRun

    runfolder = runlist{iRun};

    for iM = 1:length(modality) % cifti or nifti

        theM = modality(iM);

        % find the folder name ending with *.feat
        featdir = dir(fullfile(funcdir, runfolder, [runfolder '*.feat']));
        featPath = fullfile(funcdir, runfolder, featdir.name, resultcell{theM});

        % read contrast information (level1)
        condir = dir(fullfile(funcdir, runfolder, featdir.name, 'design.con'));
        conList = hcp_readcon(fullfile(condir.folder, condir.name)); % contrast list

        % save contrast names as contrasts_merge.txt
        con_merge_fn = fullfile(featPath, 'contrasts_merge.txt');
        fm_mkfile(con_merge_fn, conList);

        % merge for each file type
        for iFunc = 1:nFunc

            % get the file list
            theDir = dir(fullfile(featPath, coninfo{iFunc}));
            theList = {theDir.name};

            % sort the file list
            [~, theOrder] = sort(cellfun(@(x) str2double(regexp(x,'\d*','Match')), theList));
            theList = theList(theOrder);
            % full file list
            theFullList = fm_2cmdpath(fullfile(featPath, theList));

            % remove numbers
            outcell = unique(cellfun(@(x) regexprep(x, '\d', ''), theList, 'uni', false));
            % get the unique file name
            assert(numel(outcell) == 1, ['Failed to identify the unique output filename.',...
                '\nThe unique names are: \n%s.'], sprintf('%s ',outcell{:}))
            % merged file name
            mergedFn = fm_2cmdpath(fullfile(featPath, ['all', outcell{1}]));

            if theM == 1 % cifti
                % create the cmd list for -cifti-merge
                hcpcmd_merge = sprintf('wb_command -cifti-merge %s %s', mergedFn, ...
                    sprintf(' -cifti %s', theFullList{:}));

                % create the cmd list for -cifti-change-mapping
                hcpcmd_change = sprintf(['wb_command -cifti-change-mapping %s ROW ', ...
                    '%s -scalar -name-file %s'], mergedFn, ...
                    strrep(mergedFn, 'dtseries.nii', 'dscalar.nii'), fm_2cmdpath(con_merge_fn));

                tmp_cmd = {hcpcmd_merge; hcpcmd_change};

            elseif theM == 2 % nifti
                % create the cmd list for -volume-merge
                hcpcmd_merge = sprintf('wb_command -volume-merge %s %s', mergedFn, ...
                    sprintf(' -volume %s', theFullList{:}));
                % potentially there is a btter way (needs to modify codes
                % from TaskfMRILevel2.sh.

                tmp_cmd = {hcpcmd_merge};
            end

            cmdcell{iRun, iFunc, iM} = tmp_cmd;
        end
    end
end

cmdlist = vertcat(cmdcell{:});

% run the hcp commands
if runcmd
    statuscell = cellfun(@system, cmdlist, 'uni', false);
    status = cell2mat(statuscell);
else
    status = 0;
end

% make sure codes completed successfully
assert(~any(status, 'all'), 'Some of the hcp commands failed for hcp_merge.');

end