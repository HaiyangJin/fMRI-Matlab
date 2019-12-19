function subjCode = fs_subjcode(subjCode_bold, funcPath)
% This function converts the subject code for bold into subject code in
% $SUBJECTS_DIR
%
% Inputs:
%    subjCode_bold        subject code for bold data
%    funcPath            the folder where functional data are stored. The
%                         subjCode_bold should be saved at funcPath
% Output:
%    subjCode             subject code in %SUBJECTS_DIR
%
% Created by Haiyang Jin (10/12/2019)

% error if cannot find the subject_bold in that folder
if ~exist(fullfile(funcPath, subjCode_bold), 'dir')
    error('Cannot find subject Code ""%s"" in folder ""%s""', ...
        subjCode_bold, funcPath);
end

% the subjectname file in the functional folder
subjectnameFile = fullfile(funcPath, subjCode_bold, 'subjectname');

% read the subjectname file
nameCell = importdata(subjectnameFile);

if isnumeric(nameCell)
    subjCode = num2str(nameCell);
elseif iscell(nameCell)
    subjCode = nameCell{1};
end

end