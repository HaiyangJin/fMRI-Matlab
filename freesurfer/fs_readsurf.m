function [coords, faces] = fs_readsurf(surfFn, subjCode, struDir)
% [coords, faces] = fs_readsurf(surfType, subjCode, struDir)
%
% This function reads the FreeSurfer surface file with FreeSurfer Matlab 
% functions (read_surf.m). This function further corrects the vertex 
% numbers in the faces.
%
% Input:
%    surfFn         <str> the surface filename (e.g., 'lh.white') or the 
%                    full path (or relative path) to the surface filename.
%                    Default is lh.white.
%    subjCode       <str> subject code in strucPath. Default is
%                    fsaverage.
%    struDir        <str> $SUBJECTS_DIR.
%
% Output:
%    coords         <num array> Each row is one vertex and the three 
%                    columns are the coordinates for X, Y, and Z.
%    faces          <num array> Each row is one face and the three columns
%                    are the indices of the three vertices making that face.
%
% Surface files [faces for all these files should be the same]:
%   ?h.orig
%   ?h.white
%   ?h.midthickness
%   ?h.pial
%   ?h.inflated
%   ?h.sphere
%   ?h.smoothwm*
%
% Dependency: 
%    FreeSurfer Matlab functions.
%
% Example 1 (read a surf file in the current working directory):
% fs_readsurf('./lh.white');
%
% Created by Haiyang Jin (30-March-2020)

if ~exist('surfFn', 'var') || isempty(surfFn)
    surfFn = 'lh.white';
    warning('''%s'' is loaded by default.', surfFn);
end

% check if the path is available
surfPath = fileparts(surfFn);

if isempty(surfPath)
    if ~exist('subjCode', 'var') || isempty(subjCode)
        subjCode = 'fsaverage';
        warning('''fsaverage'' is used as ''subjCode'' by default.');
    end
    % use SUBJECTS_DIR as the default subject path
    if ~exist('struDir', 'var') || isempty(struDir)
        struDir = getenv('SUBJECTS_DIR');
    end
    % the default path to surf/
    surfFile = fullfile(struDir, subjCode, 'surf', surfFn);
else
    surfFile = surfFn;
end

%% Read the surface file 
assert(exist(surfFile, 'file'), 'Cannot find %s...', surfFile);
% run read_surf.m from FreeSurfer Matlab functions
[coords, faces] = read_surf(surfFile);

%% Correction the vertex indices
% correct the vertex indices in faces (by plus 1)
faces = faces + 1;
% In FreeSurfer (or Shell), the first row of matrix is 0, while in Matlab,
% the first row of matrix is 1.

end