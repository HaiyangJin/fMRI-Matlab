function mgzFile = fv_surfmgz(mgzFile, surfType, threshold)
% function fv_surfmgz(mgzFile, surfType, threshold)
%
% This function displays *.mgz file (for surface) in FreeView. [For
% displaying *.mgz for volume, please use fv_volmgz.m instead.]
%
% Inputs: 
%     mgzFile            <string> or <a cell of strings> *.mgz file (with 
%                        path) [fv_mgz.m could be used to open a gui for 
%                        selecting files.]
%     surfType           <string> the base surface file to be displayed
%                        ('inflated', 'white', 'pial', 'sphere')
%     threshold          <string> the threshold used for mgzFile
%                        [low,(mid,)high(,percentile)]
%
% Output:
%     Open FreeView to display the mgz (mgh) file
%
% Created by Haiyang Jin (21-Jan-2020)

if nargin < 2 || isempty(surfType)
    surfType = 'inflated';
end

if nargin < 3 || isempty(threshold)
    threshold = ''; % 0.5,1
end

% convert mgzFile to a cell if it is string
if ischar(mgzFile); mgzFile = {mgzFile}; end

% get the path from mgzFile
pathCell = cellfun(@fileparts, mgzFile, 'uni', false);
path = unique(pathCell);  % the path to these files
assert(numel(path) == 1); % make sure all the files are in the same folder
path = path{1}; % convert cell to string

% decide the hemi for each file
hemis = fs_hemi_multi(mgzFile, 0);  % which hemi it is (they are)?
hemiNames = unique(hemis);

% make sure the selected *.mgz is surface files
notSurf = cellfun(@isempty, hemis);
if any(notSurf)
    error('Please make sure the file %s is a surface file.\n', mgzFile{notSurf});
end
    
nHemi = numel(hemiNames);
fscmd_hemis = cell(nHemi, 1);
% create the cmd for the two hemispheres separately
for iHemi = 1:nHemi
    
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