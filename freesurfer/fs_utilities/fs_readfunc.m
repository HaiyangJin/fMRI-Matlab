function surfData = fs_readfunc(filename)
% surfData = fs_readfunc(filename)
%
% This function reads the surface functional data in FreeSurfer.
%
% Input:
%    filename         <string> the to-be-read filename (with path). [If
%                      filename is empty, the output will be []; if 
%                      filename is 'ext', the output will be a cell string 
%                      includes all the file type can be read with 
%                      fs_readfunc.m.
%
% Output:
%    surfData         <numeric array> the data matrix.
%
% Created by Haiyang Jin (14-Apr-2020)

%% Settings for extensions and the corresponding functions
% file extensions
exts = {
    '.nii', '.nii.gz';
    '.mgh', '.mgz'};
% functions
funcs = {
    @fs_readnifti;
    @load_mgh};

if ~exist('filename', 'var') || isempty(filename)
    surfData = [];
    return;
elseif ischar(filename) && strcmp(filename, 'ext')
    surfData = exts(:);
    return;
end

% make sure the file exists
assert(logical(exist(filename, 'file')), 'Cannot find the file %s.', filename);

%% Read filename
% identify the extension
whichExt = any(cellfun(@(x) endsWith(filename, x), exts), 2);

% make sure only one type of extension is identified
if sum(whichExt) == 1
    thefunc = funcs{whichExt};
else
    error('No functions have been set for reading this type of file (%s).',filename);
end

% read the file
surfData = thefunc(filename);

% if contains(filename, 'beta')
%     surfData = shiftdim(surfData, 3); % betas * vertices
% end

end