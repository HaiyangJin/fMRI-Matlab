function fs_drawlabel(subjCode, hemi, file_sig, labelname)
% This function uses "tksurfer" in FreeSurfer to draw label 
% 
% Inputs:
%    subjCode         subject code in $SUBJECTS_DIR
%    hemi             which hemispheres (must be 'lh' or 'rh')
%    file_sig         usually the sig.nii.gz from localizer scans
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
    subjCode, hemi, file_sig);
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
file_label = fullfile(subjPath, subjCode, 'label', labelname);

% rename and move this label file
tmp_fn_label = 'label.label';
file_tmp_label = fullfile(subjPath, subjCode, tmp_fn_label);

if exist(file_tmp_label, 'file')
    movefile(file_tmp_label, file_label);
end

end