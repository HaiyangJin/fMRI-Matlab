function mgzFile = fs_fvmgz(mgzFile, surfType, threshold)
% function fs_fvmgz(mgzFile, surfType, threshold)
%
% This function displays *.mgz file in FreeView.
%
% Inputs: 
%     mgzFile            *.mgz file (with path) [if is empty, a window will
%                        open for selecting the *.mgz (mgh) file.
%     surfType           <string> the base surface file to be displayed
%                        ('inflated', 'white', 'pial', 'sphere')
%     threshold          <string> the threshold used for mgzFile
%                        [low,(mid,)high(,percentile)]
%
% Output:
%     Open the FreeView to display the mgz (mgh) file
%
% Created by Haiyang Jin (21-Jan-2020)

% open a gui to select file if mgzFile is empty
if nargin < 1 || isempty(mgzFile)
    [filename, path] = uigetfile({'*.mgz;*.mgh'},...
        'Please select the mgz file to be checked...',...
        'MultiSelect', 'on');
    mgzFile = fullfile(path, filename);
else
    if ischar(mgzFile); mgzFile = {mgzFile}; end
    [pathCell, nameCell, extCell] = cellfun(@fileparts, mgzFile, 'uni', false);
    
    filename = cellfun(@(x, y) [x y], nameCell, extCell, 'uni', false);
    
    path = unique(pathCell);  
    assert(numel(path) == 1); % make sure all the files are in the same folder
    path = path{1};
end

% decide the hemi for each file
hemis = fs_hemi_multi(filename, 0);  % which hemi it is (they are)?
hemiNames = unique(hemis); 

if nargin < 2 || isempty(surfType)
    surfType = 'inflated';
end

if nargin < 3 || isempty(threshold)
    threshold = ''; % 0.5,1
end
    
nHemi = numel(hemiNames);
fscmd_hemis = cell(nHemi, 1);
% create the cmd for the two hemispheres separately
for iHemi = 1:numel(hemiNames)
    
    thisHemi = hemiNames{iHemi};
    isThisHemi = strcmp(thisHemi, hemis);
    theseMgzFile = mgzFile(isThisHemi);
    
    % file for the surface file
    surfFilename = sprintf('%s.%s', thisHemi, surfType);
    surfFile = fullfile(path, '..', 'surf', surfFilename);
    % assert the surface file is available
    if ~exist(surfFile, 'file')
        error('Cannot find surface file %s at %s.', surfFilename, path);
    end
    
    % file for the anaotation file
    annotFile = fullfile(path, '..', 'label', [thisHemi '.aparc.annot']); % annotation file
    assert(logical(exist(annotFile, 'file')));  % make sure the file is avaiable
    
    % cmd for surface file with annotation 
    fscmd_surf = sprintf([' -f %s:'... % the ?h.inflated file
        'annot=%s:annot_outline=yes:'... % the filename and settings for annotation file
        ],...% the label file and settings
        surfFile, annotFile);
    
    % cmd for overlay file (*.mgz)
    fscmd_mgz = sprintf(repmat('overlay=%s:', 1, numel(theseMgzFile)), theseMgzFile{:});
    fscmd_threshold = sprintf('overlay_threshold=%s', threshold);
    
    % cmd for this hemisphere
    fscmd_hemis{iHemi} = [fscmd_surf fscmd_mgz fscmd_threshold];
    
end

% combine the commands for two 
fscmd_hemi = [fscmd_hemis{:}];

% other cmd
fscmd_other = ' -colorscale -layout 1 -viewport 3d';

% put all commands together
fscmd = ['freeview' fscmd_hemi fscmd_other];
system(fscmd);

end