function corFaces = fs_cortexfaces(subjCode, faces, hemi)
% corFaces = fs_cortexfaces(subjCode, faces, hemi)
%
% This function only keeps the faces in the cortex label.
%
% Inputs:
%    subjCode      <string> subject code in $SUBJECTS_DIR. 
%    faces         <integer array> Px3 matrix. Each row is one face and the
%                   three columns are the three vertices making that face.
%    hemi          <string> the hemisphere information; 'lh' or 'rh'.
%
% Outputs:
%    corFaces      <integer array> P_x3 matrix. But only keep faces in the
%                   cortex label and the vertices indices will be updated.
% 
% Created by Haiyang Jin (10-Oct-2020)

% cortex mask
mask = fs_cortexmask(subjCode, hemi);

% remove faces outside the mask
isCortex = all(ismember(faces, mask), 2);

corFaces = faces;
corFaces(~isCortex, :) = [];

end