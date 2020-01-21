function fs_fvmgz(mgzFile, threshold, surfType)
% This function displays *.mgz file by calling FreeView.
%
% Inputs: 
%     mgzFile            *.mgz file (with path) [if is empty, a window will
%                        open for selecting the *.mgz (mgh) file.
%     threshold          <string> the threshold used for mgzFile
%                        [low,(mid,)high(,percentile)]
%     surfType           <string> the base surface file to be displayed
%                        ('inflated', 'white', 'pial', 'sphere')
%
% Output:
%     Open the FreeView to display the mgz (mgh) file
%
% Created by Haiyang Jin (21-Jan-2020)

% open a gui to select file if mgzFile is empty
if nargin < 1 || isempty(mgzFile)
    [filename, path] = uigetfile({'*.mgz;*.mgh'},...
        'Please select the mgz file to be checked...');
    mgzFile = fullfile(path, filename);
else
    [path, name, ext] = fileparts(mgzFile);
    filename = [name, ext];
end

if nargin < 2 || isempty(threshold)
    threshold = ''; % 0.5,1
end
    
if nargin < 3 || isempty(surfType)
    surfType = 'inflated';
end

% cmd for overlay file (*.mgz)
fscmd_mgz = sprintf('overlay=%s:overlay_threshold=%s', mgzFile, threshold);

% cmd for the surface file
hemi = fs_hemi(filename);  % which hemi it is?
surfFilename = sprintf('%s.%s', hemi, surfType);
surfFile = fullfile(path, '..', 'surf', surfFilename);

if ~exist(surfFile, 'file')
    error('Cannot find surface file %s at %s.', surfFilename, path); 
end

% cmd for the anaotation file
annotFile = fullfile(path, '..', 'label', [hemi '.aparc.annot']); % annotation file
assert(logical(exist(annotFile, 'file')));  % make sure the file is avaiable

fscmd_surf = sprintf(['freeview -f %s:'... % the ?h.inflated file
    'annot=%s:annot_outline=yes:'... % the filename and settings for annotation file
    ],...% the label file and settings
    surfFile, annotFile);

% other cmd
fscmd_other = '-colorscale -layout 1 -viewport 3d';

% put all commands together
fscmd = [fscmd_surf fscmd_mgz fscmd_other];
system(fscmd);

end