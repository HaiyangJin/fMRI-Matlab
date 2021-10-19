function curv = fs_readcurv(curvFn, subjCode, struPath)
% curv = fs_readcurv(curvFn, subjCode, struPath)
%
% This function reads the FreeSurfer curvature file with FreeSurfer Matlab 
% functions (read_curv.m).
%
% Input:
%    curvFn         <string> the curvature filename (e.g., 'lh.area') or 
%                    the full path (or relative path) to the curvature 
%                    filename. Default is lh.area.
%    subjCode       <string> subject code in strucPath. Default is
%                    fsaverage.
%    struPath       <string> $SUBJECTS_DIR.
%
% Output:
%    curv           <array of numeric> Each row is one vertex and the
%                    three columns are the coordinates for X, Y, and Z.
%
% Curvature files:
%   ?h.area
%   ?h.curv
%   ?h.sulc
%   ?h.volume
%
% Dependency: 
%    FreeSurfer Matlab functions.
%
% Example 1 (read a curv file in the current working directory):
% fs_readcurv('./lh.area');
%
% Created by Haiyang Jin (22-Apr-2020)

if ~exist('curvFn', 'var') || isempty(curvFn)
    curvFn = 'lh.area';
    warning('''%s'' is loaded by default.', curvFn);
end

% check if the path is available
curvPath = fileparts(curvFn);

if isempty(curvPath)
    if ~exist('subjCode', 'var') || isempty(subjCode)
        subjCode = 'fsaverage';
        warning('''fsaverage'' is used as ''subjCode'' by default.');
    end
    % use SUBJECTS_DIR as the default subject path
    if ~exist('struPath', 'var') || isempty(struPath)
        struPath = getenv('SUBJECTS_DIR');
    end
    % the default path to surf/
    curvFile = fullfile(struPath, subjCode, 'surf', curvFn);
else
    curvFile = curvFn;
end

%% Read the curvature file 
% run read_curv.m from FreeSurfer Matlab functions
curv = read_curv(curvFile);

end