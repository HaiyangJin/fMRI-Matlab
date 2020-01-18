function fs_drawlabel(subjCode, hemi, fileSig, labelname)
% This function uses "tksurfer" in FreeSurfer to draw label 
% 
% Inputs:
%    subjCode         subject code in $SUBJECTS_DIR
%    hemi             which hemispheres (must be 'lh' or 'rh')
%    fileSig         usually the sig.nii.gz from localizer scans
%    labelname        the label name you want to use for this label
% Output:
%    a label file saved in the label folder
%
% Created by Haiyang Jin (10/12/2019)
% For furture development, I should included to define the limits of
% p-values.

subjPath = getenv('SUBJECTS_DIR');

% create FreeSurfer command and run it
fscmd = sprintf('tksurfer %s %s inflated -aparc -overlay %s',...
    subjCode, hemi, fileSig);
system(fscmd);

%%%%%%%%%%%%%%%% Manual working in FreeSurfer %%%%%%%%%%%%%%%%%%%%%%%%%%%%
% IMPORTANT: Please make sure you started X11
% 1. click any vertex in the region
% 2. fill it with "similar" vertices
% 3. Save that area as a label file
% NOTE: please name the label as label.label in the folder
% ($SUBJECTS_DIR/subjCode/label.label) Basically, you only need to delect
% the "/" in the default folder or filename
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% created an empty file with the label filename
labelFile = fullfile(subjPath, subjCode, 'label', labelname);

% rename and move this label file
tempLabelFile = fullfile(subjPath, subjCode, 'label.label');

if exist(tempLabelFile, 'file')
    movefile(tempLabelFile, labelFile);
end

end