function outpoints = mni2tal(inpoints)
% Converts coordinates from MNI brain to best guess
% for equivalent Talairach coordinates
% FORMAT outpoints = mni2tal(inpoints)
% Where inpoints is N by 3 or 3 by N matrix of coordinates
%  (N being the number of points)
% outpoints is the coordinate matrix with Talairach points
% Matthew Brett 10/8/99
%
%%%%%%%%%%%%%%%%%%%% Noted by Haiyang %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% More explanation could be found at:
% http://imaging.mrc-cbu.cam.ac.uk/imaging/MniTalairach#Approach_2:_a_non-linear_transform_of_MNI_to_Talairach
% The "inverse" function is tal2mni.m
%
% And I'm not quite sure MNI here refers to MNI152 or MNI305 (but fee like
% it refers to MNI152).
%
% This script are used in FreeSurfer to obtain the Talairach
% coordinates from MNI305 (fsaverage).
% (https://surfer.nmr.mgh.harvard.edu/fswiki/CoordinateSystems).
% In TkSurfer:
%      Vertex Talairach = mni2tal(Vertex MNI Talairach)
% In TkMedit:
%      Talairach = mni2tal(MNI Talairach)
%
% Usage: mni2tal( [10 12 14] ) % mni2tal([x y z])

dimdim = find(size(inpoints) == 3);
if isempty(dimdim)
  error('input must be a N by 3 or 3 by N matrix')
end
if dimdim == 2
  inpoints = inpoints';
end

% Transformation matrices, different zooms above/below AC
upT = spm_matrix([0 0 0 0.05 0 0 0.99 0.97 0.92]);
downT = spm_matrix([0 0 0 0.05 0 0 0.99 0.97 0.84]);

tmp = inpoints(3,:)<0;  % 1 if below AC
inpoints = [inpoints; ones(1, size(inpoints, 2))];
inpoints(:, tmp) = downT * inpoints(:, tmp);
inpoints(:, ~tmp) = upT * inpoints(:, ~tmp);
outpoints = inpoints(1:3, :);
if dimdim == 2
  outpoints = outpoints';
end




