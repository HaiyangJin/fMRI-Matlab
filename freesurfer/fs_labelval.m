function fs_labelval(labelFn, subjCode, sigFile)
% fs_labelval(labelFn, subjCode, sigFile)
%
% It turns out that FS7 does not save the values used for creating labels
% be default. This function add these values "manually". 
%
% Inputs:
%    labelFn         <str> filename of the label file (with or without
%                     path). If path is included in labelFn, 'subjCode'
%                     will be ignored. Default is 'no.label', i.e., no labels.
%    subjCode        <str> subject code in $SUBJECTS_DIR. Default is
%                     fsaverage.
%    sigFile         <str> usually the sig.nii.gz from localizer scans.
%                     This should include the path to the file if needed.
%
% Output:
%    An updated label file with values in the fifth column.
% 
% Created by Haiyang Jin (2021-12-12)

% read the files
labelmat = fs_readlabel(labelFn, subjCode);
vals = fm_readimg(sigFile);

% values for this label
labelmat(:,5) = vals(labelmat(:,1));

% save the updated label
fs_mklabel(labelmat, subjCode, labelFn);

end