function subjCode = fs_subjcode(sessCode, funcPath)
% This function converts the subject code for bold into subject code in
% $SUBJECTS_DIR
%
% Inputs:
%    sessCode            session code for functional data (functional subject code)
%    funcPath            the folder where functional data are stored. The
%                         sessCode should be saved at funcPath
% Output:
%    subjCode             subject code in %SUBJECTS_DIR
%
% Created by Haiyang Jin (10-Dec-2019)

% error if cannot find the subjectBold in that folder
if ~exist(fullfile(funcPath, sessCode), 'dir')
    error('Cannot find subject Code ""%s"" in folder ""%s""', ...
        sessCode, funcPath);
end

% the subjectname file in the functional folder
subjectnameFile = fullfile(funcPath, sessCode, 'subjectname');

% read the subjectname file
nameCell = importdata(subjectnameFile);

if isnumeric(nameCell)
    subjCode = num2str(nameCell);
elseif iscell(nameCell)
    subjCode = nameCell{1};
end

end