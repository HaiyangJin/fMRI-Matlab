function [vtxCell, faceCell] = fs_cosmo_surfcoor(subjCode, surfCoorFile, combineHemi)
% This function converts ?h.inflated (or white or pial) into ASCII file and
% then load them into Matlab. Vertices (faces) for both hemispheres could
% be merged together. 
% 
% Created by Haiyang Jin (8/12/2019)
%
% Inputs: 
%    subjCode           subject code in $SUBJECTS_DIR
%    surfCoorFile      the coordinate file for vertices ('inflated',
%                       'white', 'pial') (default is 'inflated')
%    combineHemi        if the data of two hemispheres will be combined
%                       (default is no)
% Outputs:
%    vtxCell            vertex cell. each row is for each surface file in
%                       surfCoorFile. The first column is for left
%                       hemisphere. The column is for the right
%                       hemisphere. The third column (if there is) is for 
%                       the merged hemispheres.
%    faceCell           face cell. Same structure as vtxCell

if nargin < 2 || isempty(surfCoorFile)
    surfCoorFile = {'inflated'};
end
if nargin < 3 || isempty(combineHemi)
    combineHemi = 0;
end

% FreeSurfer setup
FS = fs_subjdir;
surfPath = fullfile(FS.subjects, subjCode, 'surf');
hemis = FS.hemis;
nHemi = FS.nHemi;

% which of the surface files will be loaded
if ~iscell(surfCoorFile)
    surfCoorFile = {surfCoorFile}; % convert to cell if necessary
end
surfExt = {'white', 'pial', 'inflated'};
whichSurfcoor = strcmp(surfExt, surfCoorFile);
if ~any(whichSurfcoor)
    error('The surface coordinate system (%s) is not supported by this function.\n',...
        surfExt{1, whichSurfcoor});
end
nSurfFile = numel(surfCoorFile);

% Create a cell for saving ASCII filenames for both hemisphere
ascFileCell = cell(nSurfFile, nHemi);
vCell = cell(nSurfFile, nHemi + combineHemi); % left, right, and (merged)
fCell = cell(nSurfFile, nHemi + combineHemi); % left, right, and (merged)

% Convert surface file to ASCII (with functions in FreeSurfer)
for iSurfExt = 1:nSurfFile
    
    for iHemi = 1:nHemi
        
        % the surface and its asc filename
        thisSurfFile = [hemis{iHemi} '.' surfCoorFile{iSurfExt}];
        thisASC = [thisSurfFile '.asc'];
        
        thisSurfPath = fullfile(surfPath, thisSurfFile);
        thisASCPath = fullfile(surfPath, thisASC);
        
        if ~exist(thisASCPath, 'file')
            % convert the surface file to ASCII file
            fscmd_asc = sprintf('mris_convert %s %s', thisSurfPath, thisASCPath);
            system(fscmd_asc);
        end
        
        % save the filename in the cell
        ascFileCell(iSurfExt, iHemi) = {thisASCPath};
        
        [vCell{iSurfExt, iHemi}, fCell{iSurfExt, iHemi}] = surfing_read(thisASCPath);
    end
    
    if combineHemi
        % Combine ASCII for two hemispheres together (with the order lh, rh)
        % this function could be obtained from http://www.cosmomvpa.org/faq.html#make-a-merged-hemisphere-from-a-left-and-right-hemisphere
        [vCell{iSurfExt, 3}, fCell{iSurfExt, 3}] = merge_surfaces(ascFileCell(iSurfExt, :));
    end
    
end

vtxCell = vCell;
faceCell = fCell;

end