function bids_fixfunc(taskStr, taskName, subjList, bidsDir)
% bids_fixfunc(taskStr, taskName, subjList, bidsDir)
% 
% The 'TaskName' field is usually missing for func json files (after
% bids_dcm2bids()). This function adds this field for func runs.
%
% Inputs:
%    taskStr       <str> wildcard strings to identify a list of func runs,
%                   for which 'TaskName' will be added to their json files.
%                   Default is empty and then all func files are treated as
%                   one task. The name will be <taskName>.
%    taskName      <str> task name to be added to the files identified by
%                   <taskStr>.
%    subjList      <cell str> a list of subject folders in <bidsDir>.
%               OR <str> wildcard strings to match the subject folders
%                   via bids_subjlist(). Default is all subjects.
%    bidsDir       <str> the BIDS directory. Default is bids_dir().
%
% Output:
%    Updated func json files.
%
% Created by Haiyang Jin (2021-10-14)
%
% See also:
% [bids_dcm2bids;] bids_mktsv; bids_fixfmap; bids_mkignore

%% Deal with inputs
if ~exist('taskStr', 'var') || isempty(taskStr)
    taskStr = '';
end
if ~endsWith(taskStr, '.json')
    taskStr = [taskStr '*.json'];
    taskStr = strrep(taskStr, '**', '*');
end

if ~exist('bidsDir', 'var') || isempty(bidsDir)
    bidsDir = bids_dir();
end

if ~exist('subjList', 'var') || isempty(subjList)
    subjList = '';
end
if ischar(subjList)
    subjList = bids_subjlist(subjList, bidsDir);
end
nSubj = length(subjList);
funccell = cell(nSubj,1);

%% find all *.json within 'func/' for each subject separately
for iSubj = 1:nSubj

    theSubjdir = dir(fullfile(bidsDir, subjList{iSubj}));

    if contains('func', {theSubjdir.name})
        % when there is no session folders
        funcdir_c = dir(fullfile(bidsDir, subjList{iSubj}, 'func', taskStr));
    else
        % when there are session folders
        funcdir_c = cellfun(@(x) ...
            dir(fullfile(bidsDir, subjList{iSubj}, x, 'func', taskStr)), ...
            {theSubjdir.name}, 'uni', false);
        funcdir_c = vertcat(funcdir_c{:});
    end

    funccell(iSubj, 1) = {funcdir_c};
end

% the whole list of func runs
funcdir = vertcat(funccell{:});

for ifunc = 1:length(funcdir)
    
    thisfname = fullfile(funcdir(ifunc).folder, funcdir(ifunc).name);
    val = jsondecode(fileread(thisfname));
    % save task name
    val.TaskName = taskName;
    str = jsonencode(val);

    % Make the json output file more human readable
    str = strrep(str, ',"', sprintf(',\n"'));
    str = strrep(str, '[{', sprintf('[\n{\n'));
    str = strrep(str, '}]', sprintf('\n}\n]'));

    fid = fopen(thisfname,'w');
    fwrite(fid,str);
    fclose(fid);

end

end