function fv_drawlabel(subjCode, hemi, sigFile, labelname)
% fv_drawlabel(subjCode, hemi, fileSig, labelname)
%
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

% make sure the sigFile exists
if ~exist(sigFile, 'file')
    error('Cannot find the file: %s.', sigFile);
end

% create FreeSurfer command and run it
fscmd = sprintf('tksurfer %s %s inflated -aparc -overlay %s',...
    subjCode, hemi, sigFile);
system(fscmd);

%%%%%%%%%%%%%%%% Manual working in FreeSurfer %%%%%%%%%%%%%%%%%%%%%%%%%%%%
% IMPORTANT: Please make sure you started X11
% 1. click any vertex in the region;
% 2. fill it with "similar" vertices;
%    1.Custom Fill;
%    2.make sure "Up to and including paths" and "up to funcitonal values
%      below threhold" are selected;
%    3.click "Fill".
% 3. Save that area as a label file;
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