function [vtxCell, faceCell] = fs_cosmo_surfcoor(subjCode, surfType, combineHemi)
% [vtxCell, faceCell] = fs_cosmo_surfcoor(subjCode, [surfType = 'sphere', ...
% combineHemi = 0])
% 
% This function load ?h.sphere (inflated or white or pial) into Matlab. The
% vertices will be masked by label/?h.cortex.label. Vertices (faces) for 
% both hemispheres can be merged together. 
%
% Inputs: 
%    subjCode           <string> subject code in $SUBJECTS_DIR.
%    surfType           <string> coordinate file for vertices ('sphere',  
%                        'inflated', 'white', 'pial') (default is 'sphere').
%    combineHemi        <logical> whether the data of two hemispheres will 
%                        be combined (default is no).
%
% Outputs:
%    vtxCell            <cell> vertex cell. each row is for each surface 
%                        file in surfCoorFile. The first column is for left
%                        hemisphere. The second column is for the right
%                        hemisphere. The third column (if there is) is for 
%                        the merged hemispheres.
%    faceCell           <cell> face cell. Same structure as vtxCell.
%
% Dependency:
%    FreeSurfer Matlab functions.
%
% Created by Haiyang Jin (8-Dec-2019)

if ~exist('surfType', 'var') || isempty(surfType)
    surfType = {'sphere'};
end

if ~exist('isCortex', 'var') || isempty(isCortex)
if ~exist('combineHemi', 'var') || isempty(combineHemi)
    combineHemi = 0;
end

% FreeSurfer setup
surfPath = fullfile(getenv('SUBJECTS_DIR'), subjCode, 'surf');
hemis = {'lh', 'rh'};
nHemi = 2;

% which of the surface files will be loaded
if ~iscell(surfType)
    surfType = {surfType}; % convert to cell if necessary
end
surfExt = {'sphere', 'white', 'pial', 'inflated', 'intermediate'};
whichSurfcoor = ismember(surfType, surfExt);
if ~any(whichSurfcoor)
    error('The surface coordinate system (''%s'') is not supported by this function.',...
        surfType{1});
end
nSurfFile = numel(surfType);

% Create a cell for saving ASCII filenames for both hemisphere
vCell = cell(nSurfFile, nHemi + combineHemi); % left, right, and (merged)
fCell = cell(nSurfFile, nHemi + combineHemi); % left, right, and (merged)

% Convert surface file to ASCII (with functions in FreeSurfer)
for iSurf = 1:nSurfFile
    
    for iHemi = 1:nHemi
        
        % the surface and its asc filename
        thisSurfFile = [hemis{iHemi} '.' surfType{iSurf}];
        thisSurfPath = fullfile(surfPath, thisSurfFile);
     
        % read FreeSurfer surface files (with FreeSurfer Matlab functions).
        [vCell{iSurf, iHemi}, fCell{iSurf, iHemi}] = fs_readsurf(thisSurfPath);
        
    end
    
    if combineHemi 
        % code modified from http://cosmomvpa.org/faq.html#make-a-merged-hemisphere-from-a-left-and-right-hemisphere
        % Combine the vertex coordinates for both hemispheres
        if ~ismember(surfType{iSurf}, {'white', 'pial','intermediate'})
            thisLeft = vCell{iSurf, 1};
            thisRight = vCell{iSurf, 2};
            
            % add offsets
            thisLeft(:,1) = thisLeft(:, 1) - max(thisLeft(:, 1));
            thisRight(:, 1) = thisRight(:, 1) - min(thisRight(:, 1));
            
            vCell{iSurf, 3} = vertcat(thisLeft, thisRight); 
        else
            vCell{iSurf, 3} = vertcat(vCell{iSurf, [1,2]});
        end
        
        % Combine the faces of vertices for both hemispheres
        nVtxLeft = size(vCell{iSurf, 1}, 1);
        fCell{iSurf, 3} = vertcat(fCell{iSurf, 1}, fCell{iSurf, 2} + nVtxLeft);
        
    end
    
end

% save the output
vtxCell = vCell;
faceCell = fCell;

end