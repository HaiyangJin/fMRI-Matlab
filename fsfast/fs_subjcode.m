function subjList = fs_subjcode(sessList, forceCell)
% subjList = fs_subjcode(sessList, forceCell)
%
% This function converts the subject codes for bold (i.e., session code in
% $FUNCTIONALS_DIR) into subject codes in $SUBJECTS_DIR.
%
% Inputs:
%    sessList         <cell str> list of session codes in $FUNCTIONALS_DIR.
%    forceCell        <boo> 1: force the output to be cell; 0: convert
%                      the 'subjList' as string if possible. Default is 0.
%
% Output:
%    subjList         <cell str> list of subject code in %SUBJECTS_DIR.
%
% Created by Haiyang Jin (10-Dec-2019)

if ~exist('forceCell', 'var') || isempty(forceCell)
    forceCell = 0;
end

if ischar(sessList); sessList = {sessList}; end

subjList = cellfun(@subjcode, sessList, 'uni', false);

if numel(subjList) == 1 && ~forceCell
    subjList = subjList{1};
end

end

function subjCode = subjcode(sessCode)

funcDIR = getenv('FUNCTIONALS_DIR');

% error if cannot find the sessCode in that folder
if ~exist(fullfile(funcDIR, sessCode), 'dir')
    error('Cannot find subject Code ''%s'' in folder ''%s''', ...
        sessCode, funcDIR);
end

% the subjectname file in the functional folder
subjectnameFile = fullfile(funcDIR, sessCode, 'subjectname');

% read the subjectname file
subjCode = fm_readtext(subjectnameFile, 1);

end