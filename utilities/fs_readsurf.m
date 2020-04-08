function [coords, faces] = fs_readsurf(surfType, hemi, subjCode, struPath)
% [coords, faces] = fs_readsurf(surfType, hemi, subjCode, struPath)
%
% This function reads the FreeSurfer surface file (?h.white, ?h.pial,
% ?h.inflated, ?h.sphere) with FreeSurfer Matlab functions (read_surf.m).
% This function only further corrects the vertex numbers in the faces.
%
% Input:
%    surfType       <string> the surface type (e.g., 'sphere') or the 
%                    full path (or relative path) to the surface filename. 
%    hemi           <string> 'lh' (default) or 'rh'.
%    subjCode       <string> subject code in $SUBJECTS_DIR.
%    struPath       <string> $SUBJECTS_DIR.
%
% Output:
%    coords         <array of numeric> Each row is one vertex and the
%                    three columns are the coordinates for X, Y, and Z.
%    faces          <array of numeric> Each row is one face and the
%                    three columns are the indices of the three vertices
%                    making that face.
%
% Dependency:
%    FreeSurfer Matlab functions.
%
% Created by Haiyang Jin (30-March-2020)

if nargin < 1 || isempty(surfType)
    surfType = 'sphere';
end

surfPath = fileparts(surfType);

if isempty(surfPath)
    if nargin < 2 || isempty(hemi)
        hemi = 'lh';
    end
    if nargin < 3 || isempty(subjCode)
        subjCode = 'fsaverage';
    end
    if nargin < 4 || isempty(struPath)
        struPath = getenv('SUBJECTS_DIR');
    end
    % the default path to surf/
    surfPath = fullfile(struPath, subjCode, 'surf');
    surfFilename = fullfile(surfPath, [hemi '.' surfType]);
else
    surfFilename = surfType;
end

%% Read the surface file 
% run read_surf.m from FreeSurfer Matlab functions
[coords, faces] = read_surf(surfFilename);

%% Correction the vertex indices
% correct the vertex indices in faces (by plus 1)
faces = faces + 1;
% In FreeSurfer (or Shell), the first row of matrix is 0, while in Matlab,
% the first row of matrix is 1.

end