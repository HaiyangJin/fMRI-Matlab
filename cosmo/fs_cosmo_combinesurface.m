function ds_combine = fs_cosmo_combinesurface(ds_cell)
% This function combines the functional (surface) data of two hemispheres
% together (or maybe more). 
%
% Inputs:
%    ds_cell       a cell of cosmo dataset for both hemispheres (or more)
% Outputs:
%    ds_combine    the combined cosmo dataset
%
% Created by Haiyang Jin (15/12/2019)

% number of vertices in total for all datasets in ds_cell
nVtxTotal = sum(cellfun(@(x) numel(x.a.fdim.values{1, 1}), ds_cell));

% number of datasets
nds = numel(ds_cell);

% empty cell for saving updated datasets
ds_update = cell(1, nds); 
startVtxNum = 0;

for ids = 1:nds
    
    % this dataset
    this_ds = ds_cell{ids};
    
    % update the node_indices for this dataset to be unique (different from
    % node_indices in other datasets)
    this_ds.fa.node_indices = this_ds.fa.node_indices + startVtxNum;
    % update the start vertex number for next dataset
    startVtxNum = startVtxNum + numel(this_ds.a.fdim.values{1, 1});
    
    % update a.fdim.values (dimensions) relative to all datasets
    this_ds.a.fdim.values = {1:nVtxTotal};
    
    % save the updated dataset
    ds_update(1, ids) = {this_ds};
    
end

% combine all updated datasets
ds_combine = cosmo_stack(ds_update, 2);
