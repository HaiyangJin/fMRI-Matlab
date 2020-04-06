function ds = fs_cosmo_surface(surfFn, varargin)
% ds = fs_cosmo_surface(filename, varagin)
%
% Load the surface data in FreeSurfer as a data set for CoSMoMVPA.
%
% Inputs:
%   surfFn          filename of surface data to be loaded. This function
%                     only supports the beta.nii.gz (or maybe also other
%                     *.nii.gz) from FreeSurfer for surface.
%   'targets', t      Px1 targets for P samples; these will be stored in
%                     the output as ds.sa.targets
%   'chunks', c       Px1 chunks for P samples; these will be stored in the
%                     the output as ds.sa.chunks
% Output:
%   ds                dataset struct
%
% No exmaples :)
%
% Notes:
%   - data can be mapped back to a label file format using
%     fs_save2surf.m
%
% Dependency:
%   - for FreeSurfer files, it requires the FreeSurfer
%     toolbox, available from: https://surfer.nmr.mgh.harvard.edu/
%
% Created by Haiyang Jin (8-Dec-2019)

%% modified from cosmo_surface_dataset.m
% defaults=struct();
% defaults.targets=[];
% defaults.chunks=[];
%
% params = cosmo_structjoin(defaults, varargin);
%
% ds=get_dataset(fn);
%
% % set targets and chunks
% ds=set_vec_sa(ds,'targets',params.targets);
% ds=set_vec_sa(ds,'chunks',params.chunks);
%
% % check consistency
% cosmo_check_dataset(ds,'surface');

defaults=struct();
defaults.targets=[];
defaults.labels=[];
defaults.chunks=[];

params = cosmo_structjoin(defaults, varargin);

%% ds=get_dataset(filename);
ds = struct;

if ~exist(surfFn, 'file')
    error('Cannot find file %s', surfFn);
end

% load data
data = fs_readnifti(surfFn, 1); % only load data
data = data'; % betas * vertices

% only keep first n rows of samples if Target information is available
if ~isempty(params.targets)
    nTarget = numel(params.targets);
    data = data(1:nTarget, :);
end

% .fa
ds.fa.node_indices = 1:size(data, 2);

% .a
ds.a.fdim.labels = {'node_indices'};
ds.a.fdim.values = {1:size(data,2)};

% samples
ds.samples = data;

% % add the filename to .a.file (maybe incorrect)
% ds.a.file = {filename};

%% set targets and chunks
ds=set_vec_sa(ds, 'targets',params.targets);
ds=set_vec_sa(ds, 'labels',params.labels);
ds=set_vec_sa(ds, 'chunks',params.chunks);

% check consistency
cosmo_check_dataset(ds,'surface');

end

function ds=set_vec_sa(ds, label, values)
% set the parameters
if isempty(values)
    return;
end
if numel(values)==1
    nsamples=size(ds.samples,1);
    values=repmat(values,nsamples,1);
end
ds.sa.(label)=values(:);
end
