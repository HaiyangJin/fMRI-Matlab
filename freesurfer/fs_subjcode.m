function subjList = fs_subjcode(sessList, funcPath, forceCell)
% subjList = fs_subjcode(sessList, funcPath, forceCell
%
% This function converts the subject code for bold into subject code in
% $SUBJECTS_DIR
%
% Inputs:
%    sessList         <cell string> list of session codes in funcPath.
%    funcPath         <string> the full path to the functional folder.
%    forceCell        <logical> 1: force the output to be cell; 0: convert
%                      the 'subjList' as string if possible. Default is 0.
%
% Output:
%    subjList         <cell string> list of subject code in %SUBJECTS_DIR.
%
% Created by Haiyang Jin (10-Dec-2019)

% use the path saved in the global environment if needed
if ~exist('funcPath', 'var') || isempty(funcPath)
    funcPath = getenv('FUNCTIONALS_DIR');
end
if ~exist('forceCell', 'var') || isempty(forceCell)
    forceCell = 0;
end

if ischar(sessList); sessList = {sessList}; end

subjList = cellfun(@(x) subjcode(x, funcPath), sessList, 'uni', false);

if numel(subjList) == 1 && ~forceCell
    subjList = subjList{1};
end

end

function subjCode = subjcode(sessCode, funcPath)

% error if cannot find the sessCode in that folder
if ~exist(fullfile(funcPath, sessCode), 'dir')
    error('Cannot find subject Code ""%s"" in folder ""%s""', ...
        sessCode, funcPath);
end

% the subjectname file in the functional folder
subjectnameFile = fullfile(funcPath, sessCode, 'subjectname');

% read the subjectname file
subjCode = fs_readtext(subjectnameFile);

end