function subjCode = fs_subjcode(subjCode_bold, path_fMRI)
% This function converts the subject code for bold into subject code in
% $SUBJECTS_DIR
%
% Inputs:
%    subjCode_bold        subject code for bold data
%    path_fMRI            the folder where functional data are stored. The
%                         subjCode_bold should be saved at path_fMRI
% Output:
%    subjCode             subject code in %SUBJECTS_DIR
%
% Created by Haiyang Jin (10/12/2019)

% error if cannot find the subject_bold in that folder
if ~exist(fullfile(path_fMRI, subjCode_bold), 'dir')
    error('Cannot find subject Code ""%s"" in folder ""%s""', ...
        subjCode_bold, path_fMRI);
end

% the subjectname file in the functional folder
subjectnameFile = fullfile(path_fMRI, subjCode_bold, 'subjectname');

% read the subjectname file
nameCell = importdata(subjectnameFile);

subjCode = nameCell{1};

end