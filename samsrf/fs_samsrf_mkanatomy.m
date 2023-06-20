function fs_samsrf_mkanatomy(subjCode, sessCode, hemi, samsrfDir)
% fs_samsrf_mkanatomy(subjCode, sessCode, hemi, samsrfDir)
%
% Inputs:
%     subjCode     <str> subject code in $SUBJECTS_DIR.
%     sessCode     <str> session/folder to be created in $SAMSRF_DIR.
%     hemi         <str> hemispheres, 'lh', or 'rh'.
%     samsrfDir    <str> directory for SamSrf analysis, could be the same
%                   as $SUBJECTS_DIR. Default to $SAMSRF_DIR.
%
% Created by Haiyang Jin (2023-June-20)

% deal with inputs
assert(ismember(hemi, {'lh', 'rh'}), '"hemi" has to be "lh" or "rh".')

if ~exist('samsrfDir', 'var') || isempty(samsrfDir)
    samsrfDir = getenv('SAMSRF_DIR');
end

% load anatomy surface files
[V0, F] = fs_readsurf([hemi '.white'], subjCode); % Grey-white surface
P = fs_readsurf([hemi '.pial'], subjCode); % Pial surface
I = fs_readsurf([hemi '.inflated'], subjCode); % Inflated surface
S = fs_readsurf([hemi '.sphere'], subjCode); % Spherical surface
N = P - V0; % Cortical vectors for each vertex 

C = fs_readcurv([hemi '.curv'], subjCode); % Cortical curvature
A = fs_readcurv([hemi '.area'], subjCode); % Cortical surface area
T = fs_readcurv([hemi '.thickness'], subjCode); % Cortical thickness

% Make Anat for SamSrf
Anat = struct;
Anat.Version = samsrf_version;
Anat.Structural = fullfile(getenv('SUBJECTS_DIR'), subjCode);
Anat.Hemisphere = hemi;
Anat.Vertices = V0;
Anat.Pial = P;
Anat.Inflated = I;
Anat.Sphere = S;
Anat.Faces = F;
Anat.Normals = N;
Anat.Curvature = C';
Anat.Area = A';
Anat.Thickness = T';

save(fullfile(samsrfDir, sessCode, 'anatomy', [hemi '_anat']), 'Anat', '-v7.3');

end
