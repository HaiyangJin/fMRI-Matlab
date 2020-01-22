function mgzFile = fv_mgz(mgzFile, surfType, runFV)
% mgzFile = fv_mgz(mgzFile, surfType, runFV)
%
% This function displays *.mgz file (for surface or volume) in FreeView.
%
% Inputs: 
%     mgzFile            <string> or <a cell of strings> *.mgz file (with 
%                        path) [if is empty, a window will open for 
%                        selecting the *.mgz (mgh) file.
%     surfType           <string> the base surface file to be displayed
%                        ('inflated', 'white', 'pial', 'sphere')
%     runFV              <logical> run Freeview or not
%
% Output:
%     Open FreeView to display the mgz (mgh) file
%
% Created by Haiyang Jin (22-Jan-2020)

% open a gui to select file if mgzFile is empty
if nargin < 1 || isempty(mgzFile)
    % set the default folder is SUBJECTS_DIR if it is not empty
    structPath = getenv('SUBJECTS_DIR');
    if isempty(structPath)
        startPath = pwd;
    else
        startPath = structPath;
    end
    
    % open a gui to select mgz files
    [filename, path] = uigetfile({fullfile(startPath, '*.mgz;*.mgh')},...
        'Please select the mgz file to be checked...',...
        'MultiSelect', 'on');
    mgzFile = fullfile(path, filename);
    
    % convert to cell if mgzFile is a string (when only one file is
    % selected)
    if ischar(mgzFile); mgzFile = {mgzFile}; end
end

if nargin < 2
    surfType = '';
end

if nargin < 3
    runFV = 1;
end

% stop here if do not display the files in freeview
if ~runFV
    return;
end

% which hemi is it (are they)? 
hemis = fs_hemi_multi(mgzFile, 0);  
% the empty value means that the file is for both hemisphere (i.e., volume
% file)
isBoth = unique(cellfun(@isempty, hemis));

% error if some of selected files are for volumes and some files are for
% surfaces
if numel(isBoth) ~= 1
    error(['Please only select one type of mgz files. [all volume mgz '...
        'or all surface mgz files].']);
end

% set info for the two functions
fvString = {'surface', 'volume'};

% display the mgz files
fprintf('\nDisplaying %s files in FreeView...\n\n', fvString{isBoth + 1});
if isBoth
    mgzFile = fv_volmgz(mgzFile);
else
    mgzFile = fv_surfmgz(mgzFile, surfType);
end

end
