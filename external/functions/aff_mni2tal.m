function outpoint = aff_mni2tal(inpoint)
% Converting MNI to Talairach

% Note by Haiyang
% Code get from http://imaging.mrc-cbu.cam.ac.uk/imaging/MniTalairach
% #Approach_1:_redo_the_affine_transform

Tfrm = [0.88 0 0 -0.8;0 0.97 0 -3.32; 0 0.05 0.88 -0.44;0 0 0 1];
tmp = Tfrm * [inpoint 1]';
outpoint = tmp(1:3)';