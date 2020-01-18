function subjCode = fs_subjcode(subjCodeSess, funcPath)
% This function converts the subject code for bold into subject code in
% $SUBJECTS_DIR
%
% Inputs:
%    subjCodeBold        subject code for bold data
%    funcPath            the folder where functional data are stored. The
%                         subjCodeBold should be saved at funcPath
% Output:
%    subjCode             subject code in %SUBJECTS_DIR
%
% Created by Haiyang Jin (10/12/2019)

% error if cannot find the subjectBold in that folder
if ~exist(fullfile(funcPath, subjCodeSess), 'dir')
    error('Cannot find subject Code ""%s"" in folder ""%s""', ...
        subjCodeSess, funcPath);
end

% the subjectname file in the functional folder
subjectnameFile = fullfile(funcPath, subjCodeSess, 'subjectname');

% read the subjectname file
nameCell = importdata(subjectnameFile);

if isnumeric(nameCell)
    subjCode = num2str(nameCell);
elseif iscell(nameCell)
    subjCode = nameCell{1};
end

end