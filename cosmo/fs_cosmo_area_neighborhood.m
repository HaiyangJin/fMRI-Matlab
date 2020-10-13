function [nbrhood]=fs_cosmo_area_neighborhood(ds, surfs, areas, varargin)
% fs_cosmo_area_neighborhood(ds, surfs, areas, varargin)
%
% This function defines neighborhood for surface-based searchlight
% according to the size (mm^2) on '?h.area' in FreeSurfer. This function is
% modified from cosmo_surficial_neighborhood.m.
%
% Inputs:
%    ds          <structure> surface dataset in CoSMoMVPA format.
%    surfs       <cell> 1x2 cell. The first is the vertex coordinates and
%                 the second is the faces of the surface.
%    areas       <numeric array> 1xN array. Each row is the area size for 
%                 one vertex.
% Varargin:
%    'areaMax'   <numeric> select neighbors whose total area is just under
%                 'area'. Default is 100 (mm^2).
%
% Created by Haiyang Jin (13-Oct-2020)
%
% See also:
% cosmo_surficial_neighborhod_area

defaultOpts = struct(...
    'areaMax', 100 ...
    );

options = fs_mergestruct(defaultOpts, varargin{:});
areaMax = options.areaMax;

% make sure ds is surface data
assert(cosmo_check_dataset(ds,'surface',false));

%% Create nbrhood
vertices = surfs{1};
faces = surfs{2};

%%%% (below) copied from cosmo_surficial_neighborhood %%%%
dim_label='node_indices';

[two,fdim_index,attr_name,dim_name]=cosmo_dim_find(ds,...
    dim_label,true);

fdim_nodes=ds.a.(dim_name).values{fdim_index};
fa_indices=ds.(attr_name).(dim_label);

if ~isequal(sort(fdim_nodes), unique(fdim_nodes))
    error('values in .a.%s.values{%d} are not all unique',...
        dim_name, fdim_index);
end

% - unq_nodes contains the node index associated with each unique
%   node_indices feature in the dataset
[fa_idxs,unq_fa_indices]=cosmo_index_unique(fa_indices');
unq_nodes=fdim_nodes(unq_fa_indices);

nvertices=size(vertices,1);

too_large_index=find(unq_nodes>nvertices,1);
if any(too_large_index)
    error(['surface has %d vertices, but maximum .fa.%s '...
        'is %d'],...
        nvertices,dim_label,fa_node_ids(too_large_index));
end

ignore_vertices_msk=true(nvertices,1);
ignore_vertices_msk(unq_nodes)=false;

vertices(ignore_vertices_msk,:)=NaN;

% set mapping from nodes to feature ids
ncenters=numel(unq_fa_indices);
node2feature_ids=cell(1,nvertices);
for k=1:ncenters
    node=unq_nodes(k);
    if ignore_vertices_msk(node)
        feature_ids=cell(1,0);
    else
        feature_ids=fa_idxs{k};
    end
    node2feature_ids{node}=feature_ids;
end

%%%%%%%%%%%%%%%%%%% Modified %%%%%%%%%%%%%%%%%%%%%%%%%%%
% run node selection
% [n2ns,radii]=surfing_nodeselection(vertices',faces',circle_def,...
%     opt.metric,opt.progress);
[n2ns,radii,areaSize] = area_nodeselection(vertices', faces', areas, areaMax);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set output
nbrhood=struct();
nbrhood.a.fdim.labels={'node_indices'};
nbrhood.a.fdim.values={fdim_nodes};

nbrhood.neighbors=cell(ncenters,1);
nbrhood.fa.areas=zeros(1,ncenters);
nbrhood.fa.radius=zeros(1,ncenters);
nbrhood.fa.node_indices=zeros(1,ncenters);


for k=1:ncenters
    center_node=unq_nodes(k);
    nbrhood.fa.node_indices(k)=unq_fa_indices(k);
    nbrhood.fa.radius(k)=radii(center_node); % updated
    nbrhood.fa.areas(k)=areaSize(center_node); % updated
    
    if ignore_vertices_msk(center_node)
        around_feature_ids=zeros(1,0);
    else
        around_nodes=n2ns{center_node};
        around_feature_ids=cat(1,node2feature_ids{around_nodes});
    end
    
    nbrhood.neighbors{k}=around_feature_ids(:)';
end


% add ds attributes to nbrhood
origin=struct();
origin.a=ds.a;
origin.fa=ds.fa;
nbrhood.origin=origin;

cosmo_check_neighborhood(nbrhood,ds);

%%%% (above) copied from cosmo_surficial_neighborhood %%%%

end