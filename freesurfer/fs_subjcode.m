function subjCode = fs_subjcode(sessCode, funcPath)
% subjCode = fs_subjcode(sessCode, funcPath)
%
% This function converts the subject code for bold into subject code in
% $SUBJECTS_DIR
%
% Inputs:
%    sessCode         <string> session code in funcPath.
%    funcPath         <string> the full path to the functional folder.
%
% Output:
%    subjCode         <string> subject code in %SUBJECTS_DIR.
%
% Created by Haiyang Jin (10-Dec-2019)

% use the path saved in the global environment if needed
if nargin < 2 || isempty(funcPath)
    funcPath = getenv('FUNCTIONALS_DIR');
end

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