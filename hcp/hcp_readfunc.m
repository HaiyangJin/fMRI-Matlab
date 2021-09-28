function [data, info] = hcp_readfunc(filename)
% [data, info] = hcp_readfunc(filename)
%
% This function reads the functional data generated by HCP.
%
% Input:
%    filename         <string> the to-be-read filename (with path). [If
%                      filename is empty, the output will be []; if 
%                      filename is 'ext', the output will be a cell string 
%                      includes all the file type can be read with 
%                      hcp_readfunc.m.
%
% Output:
%    data             <numeric array> the data matrix.
%    info             The other available information. 
%
% Created by Haiyang Jin (2021-09-28)

%% Settings for extensions and the corresponding functions
% file extensions
exts = {
    '.nii.gz'; % nifti
    '.nii';    % cifti
    '.gii'};   % gifti
% functions
funcs = {
    @load_nii;    % nifti
    @cifti_read;  % cifti
    @gifti};      % gifti
% data fieldname
fieldn = {
    'img';
    'cdata';
    'cdata'};

if ~exist('filename', 'var') || isempty(filename)
    data = [];
    return;
end

% make sure the file exists
assert(exist(filename, 'file'), 'Cannot find the file %s.', filename);

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
data = info.(fieldn{whichExt});

end
