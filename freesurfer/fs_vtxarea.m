function area = fs_vtxarea(vtxIdx, subjCode, surface)
% area = fs_vtxarea(vtxIdx, subjCode, surface)
% 
% This function calculates the areas (mm2) for all the input vertices based
% on ?h.area in surf/.
% 
% Inputs:
%    vtxIdx          <num cell> array of vertex indices. 
%                     Each cell contains all the vertex indices for one group.
%    subjCode        <str> subject code in $SUBJECTS_DIR.
%    surface         <str> ?h.[surface]. If [surface] ends with 'area', the
%                     output area is obtained from ?h.area (i.e., area on 
%                     ?h.white calculated by FreeSurfer). If [surface] is a
%                     surface (e.g., ?h.white, ?h.pial, ?h.intermediate),
%                     the area is calculated via surfing_surfacearea().
%
% Output:
%    area            <array> area (in mm2) for all the input vertices.
%
% Created by Haiyang Jin (9-Apr-2020)
%
% See also:
% fs_labelarea

% convert the numeric vector to a cell
if isnumeric(vtxIdx)
    vtxIdx = {vtxIdx};
end

if ~exist('subjCode', 'var') || isempty(subjCode)
    subjCode = 'fsaverage';
end

if ~exist('surface', 'var') || isempty(surface)
    surface = 'lh.area';
elseif ismember(surface, {'lh', 'rh'})
    surface = [surface, '.area'];
end

if endsWith(surface, 'area')
    % area files (?h.area)
    vtx2areas = fs_readcurv(surface, subjCode);
else
    % read the surface and calculate the area
    [coords, faces] = fs_readsurf(surface, subjCode);
    vtx2areas = surfing_surfacearea(coords, faces);
end

% calculate the area for the input vertices
area = cellfun(@(x) sum(vtx2areas(x)), vtxIdx);

end