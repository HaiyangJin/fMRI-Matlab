function [data, info] = fm_readimg(filename)
% [data, info] = fm_readimg(filename)
%
% This function reads the imaging files. Currently supports are: 
%     *.mgz or *.mgh  -- needs FreeSurfer Matlab functions. You may need to
%           set it up with fs_setup.
%     *.nii.gz -- needs FreeSurfer Matlab functions (fs_setup).
%     *.nii -- (cifti or nifti files) *.nii will be tried as cifti files
%           first, which requires "cifti-matlab" toolbox. If it failed, 
%           *.nii will be read as nifti files using load_nifti (fs_setup).
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
    @fs_readmgh;       % mgh; mgz
    @load_nifti;       % nifti
    @cifti_nii_read;   % cifti
    @gifti;            % gifti
    };       
% data fieldname
fieldn = {
    {'vol'};
    {'vol'};
    {'cdata', 'vol'};
    {'cdata'};
    };

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
thefieldn = fieldn{whichExt};
isava = ismember(thefieldn, fieldnames(info));

if any(isava)
    data = squeeze(info.(thefieldn{isava}));
else
    warning('The file does not seem to be an imaging file.');
    data = [];
end

end

function outstruct = cifti_nii_read(filename)
% try to read *.nii as cifti and then nifti.
try
    % try cifti
    outstruct = cifti_read(filename);
catch
    % try nifti
    outstruct = load_nifti(filename);
end
end
