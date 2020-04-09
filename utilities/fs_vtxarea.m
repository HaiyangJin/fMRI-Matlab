function area = fs_vtxarea(vertices, subjCode, hemi, struPath)
% area = fs_vtxarea(vertices, subjCode, hemi, struPath)
% 
% This function calculates the areas (mm2) for all the input vertices based
% on ?h.area in surf/.
% 
% Inputs:
%    vertices        <cell of numeric vector> array of vertex indices. 
%                     Each cell contains all the vertex indices for one group.
%    subjCode        <string> subject code in $SUBJECTS_DIR.
%    hemi            <string> 'lh' or 'rh'.
%    struPath        <string> $SUBJECTS_DIR.
%
% Output:
%    area            <array of numeric> area (in mm2) for all the input 
%                     vertices.
%
% Created by Haiyang Jin (9-Apr-2020)

% convert the numeric vector to a cell
if isnumeric(vertices)
    vertices = {vertices};
end

if nargin < 2 || isempty(subjCode)
    subjCode = 'fsaverage';
end

if nargin < 3 || isempty(hemi)
    hemi = 'lh';
end

if nargin < 4 || isempty(struPath)
    struPath = getenv('SUBJECTS_DIR');
end

% area files
areaFn = sprintf('%s.area', hemi);
areaFile = fullfile(struPath, subjCode, 'surf', areaFn);

% read the area file
areaData = read_curv(areaFile);

% calculate the area for the input vertices
area = cellfun(@(x) sum(areaData(x)), vertices);

end