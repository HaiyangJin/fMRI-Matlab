function [data, info] = fm_readimg(filename, isnifti)
% [data, info] = fm_readimg(filename, isnifti)
%
% This function reads the imaging files. Currently supports are: 
%     *.mgz or *.mgh  -- needs FreeSurfer Matlab functions. You may need to
%           set it up with fs_setup.
%     *.nii.gz -- needs FreeSurfer Matlab functions (fs_setup).
%     *.nii -- (cifti files only) *.nii will be regarded as cifti files. It
%           requires "cifti-matlab" toolbox. To read *.nii as nifti files, 
%           use fs_readnifti or load_nii.
%     *.gii --  *.gii will be read as functional data (not sure if other  
%           data type, e.g., surface, will work). It requires "gifti"
%           toolbox.
%
% Input:
%    filename         <string> the to-be-read filename (with path). [If
%                      filename is empty, the output will be []; if
%                      filename is 'ext', the output will be a cell string
%                      includes all the file type can be read with
%                      fm_readimg. 
%
% Output:
%    data             <numeric array> the data matrix.
%    info             The other available information.
%
% % Example 1:
% [data,info]=fm_readimg('/Applications/freesurfer/7.2/subjects/fsaverage/mri/brain.mgz');
%
% Created by Haiyang Jin (2021-10-12)
%
% See also:
% fs_readfunc; hcp_readfunc

%% Deal with inputs
if ~exist('filename', 'var') || isempty(filename)
    data = [];
    return;
end

if ~exist('isnifti', 'var') || isempty(isnifti)
    isnifti = 0;
end

%% Settings for extensions and the corresponding functions
% file extensions
exts = {
    {'.mgh', '.mgz'};    % from freesurfer
    {'.nii.gz'}; % nifti
    {'.nii'};    % cifti
    {'.gii'};   % gifti
    };
% functions
funcs = {
    @fs_readmgh;   % mgh; mgz
    @load_nifti;   % nifti
    @cifti_read;   % cifti
    @gifti;        % gifti
    };       
% data fieldname
fieldn = {
    'vol';
    'vol';
    'cdata';
    'cdata';
    };

if isnifti; funcs{4} = @load_nifti; end % read *.nii as nifti

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
info = thefunc(filename);

% extract data
if isfield(info, fieldn{whichExt})
    data = squeeze(info.(fieldn{whichExt}));
else
    warning('The file does not seem to be an imaging file.');
    data = [];
end

end
