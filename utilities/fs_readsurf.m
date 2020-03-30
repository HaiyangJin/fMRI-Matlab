function [vertex_coords, faces] = fs_readsurf(surfFilename)
%
%
% This function reads the FreeSurfer surface file (?h.white, ?h.pial,
% ?h.inflated, ?h.sphere) with FreeSurfer Matlab functions (read_surf.m).
% This function only further corrects the vertex numbers in the faces.
%
% Input:
%    surfFilename        <string> the full path (or relative path) to the 
%                         surface filename.
%
% Output:
%    vertex_coords       <array of numeric> Each row is one vertex and the
%                         three columns are the coordinates for X, Y, and Z.
%    faces               <array of numeric> Each row is one face and the
%                         three columns are the indices of the three vertices
%                         making that face.
%
% Dependency:
%    FreeSurfer Matlab functions.
%
% Created by Haiyang Jin (30-March-2020)

%% Read the surface file 
% run read_surf.m from FreeSurfer Matlab functions
[vertex_coords, faces] = read_surf(surfFilename);

%% Correction
% correct the vertex indices in faces (by plus 1)
faces = faces + 1;

% In FreeSurfer (or Shell), the first row of matrix is 0, while in Matlab,
% the first row of matrix is 1.

end