function area = fs_vtxarea(vtxIdx, subjCode, hemi, struDir)
% area = fs_vtxarea(vtxIdx, subjCode, hemi, struDir)
% 
% This function calculates the areas (mm2) for all the input vertices based
% on ?h.area in surf/.
% 
% Inputs:
%    vtxIdx          <cell num vector> array of vertex indices. 
%                     Each cell contains all the vertex indices for one group.
%    subjCode        <str> subject code in $SUBJECTS_DIR.
%    hemi            <str> 'lh' or 'rh'.
%    struDir         <str> $SUBJECTS_DIR.
%
% Output:
%    area            <num array> area (in mm2) for all the input vertices.
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

if ~exist('hemi', 'var') || isempty(hemi)
    hemi = 'lh';
end

if ~exist('struDir', 'var') || isempty(struDir)
    struDir = getenv('SUBJECTS_DIR');
end

% area files
areaFn = sprintf('%s.area', hemi);
areaFile = fullfile(struDir, subjCode, 'surf', areaFn);

% read the area file
areaData = read_curv(areaFile);

% calculate the area for the input vertices
area = cellfun(@(x) sum(areaData(x)), vtxIdx);

end