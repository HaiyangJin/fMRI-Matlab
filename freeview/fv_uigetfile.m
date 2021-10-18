function olFile = fv_uigetfile(subjCode, surfType, runFV)
% olFile = fv_uigetfile(subjCode, surfType, runFV)
%
% This function uses GUI to select *.mgz, *.mgh, *.nii, *.nii.gz (and *.gii)
% and then display overlay file (for surface or volume) in FreeView.
%
% Inputs: 
%     subjCode        <str> Subject code in $SUBJECTS_DIR.
%     surfType        <str> the base surface file to be displayed
%                      ('inflated'[default], 'white', 'pial', 'sphere'). 
%     runFV           <boo> run Freeview or not. Default is 1.
%
% Output:
%     Open FreeView to display the overlay file.
%
% Created by Haiyang Jin (22-Jan-2020)
%
% See also:
% fv_surf; fv_vol

%% open a gui to select file if olFile is empty
% set the default folder is SUBJECTS_DIR if it is not empty
struPath = getenv('SUBJECTS_DIR');
if isempty(struPath)
    startPath = pwd;
else
    startPath = struPath;
end

% open a gui to select mgz files
[filename, path] = uigetfile({fullfile(startPath, '*.mgz;*.mgh;*.nii;*.nii.gz;*.gii')},...
    'Please select the overlay file to be displayed...',...
    'MultiSelect', 'on');
olFile = fullfile(path, filename);

% convert to cell if olFile is a string (when only one file is selected)
if ischar(olFile); olFile = {olFile}; end

%% Deal with inputs
if ~exist('subjCode', 'var') || isempty(subjCode)
    subjCode = '';
end

if ~exist('surfType', 'var') || isempty(surfType)
    surfType = 'inflated';
end

if ~exist('runFV', 'var') || isempty(runFV)
    runFV = 1;
end

% stop here if do not display the files in freeview
if ~runFV
    return;
end

% which hemi is it (are they)? 
hemis = fm_hemi_multi(olFile, 0);  
% the empty value means that the file is for both hemisphere (i.e., volume
% file)
isBoth = unique(cellfun(@isempty, hemis));

% error if some of selected files are for volumes and some files are for
% surfaces
if numel(isBoth) ~= 1
    error(['Please only select one type of mgz files. [all volume '...
        'or all surface files].']);
end

% set info for the two functions
fvString = {'surface', 'volume'};

% display the mgz files
fprintf('\nDisplaying %s files in FreeView...\n\n', fvString{isBoth + 1});
if isBoth
    olFile = fv_vol(olFile);
else
    olFile = fv_surf(olFile, subjCode, 'surftype', surfType);
end

end
