function area = fs_vtxarea(vtxIdx, subjCode, hemi, struPath)
% area = fs_vtxarea(vtxIdx, subjCode, hemi, struPath)
% 
% This function calculates the areas (mm2) for all the input vertices based
% on ?h.area in surf/.
% 
% Inputs:
%    vtxIdx          <cell of numeric vector> array of vertex indices. 
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
if isnumeric(vtxIdx)
    vtxIdx = {vtxIdx};
end

if ~exist('subjCode', 'var') || isempty(subjCode)
    subjCode = 'fsaverage';
end

if ~exist('hemi', 'var') || isempty(hemi)
    hemi = 'lh';
end

if ~exist('struPath', 'var') || isempty(struPath)
    struPath = getenv('SUBJECTS_DIR');
end

% area files
areaFn = sprintf('%s.area', hemi);
areaFile = fullfile(struPath, subjCode, 'surf', areaFn);

% read the area file
areaData = read_curv(areaFile);

% calculate the area for the input vertices
area = cellfun(@(x) sum(areaData(x)), vtxIdx);

end