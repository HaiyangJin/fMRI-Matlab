function rmvIdx = fs_cosmo_nbrcortex(nbrhood, subjCode, hemi, nNonVtx)
% nbrhood = fs_cosmo_nbrcortex(nbrhood, subjCode, hemi, nNonVtx)
%
% This function removes .neighbors whose vertices are outside the cortex
% label if certain criteria is met, i.e., the outside cortex vertex number
% is larger than nNonVtx. 
%
% Inputs:
%    nbrhood       <struct> nbrhood structure; can be obtained via
%                   cosmo_surficial_neighborhood. 
%    subjCode      <string> subject code in $SUBJECTS_DIR.
%    hemi          <string> hemisphere information. 'lh' or 'rh'.
%    nNonVtx       <integer> the critical number of non-cortex vertices.
%                   neighbors in .neighbors will be removed if its
%                   non-cortex vertices are larger than this value. Default
%                   is 0.
%
% Output:
%    nbrhood       <struct> nbrhood structure.
%
% Created by Haiyang Jin (10-Oct-2020)

if ~exist('nNonVtx', 'var') || isempty(nNonVtx)
    nNonVtx = 0;
end

% the cortex mask
corMask = sort(fs_cortexmask(subjCode, hemi));

% whether there is a 
% nonVtx = cellfun(@(x) sum(~ismember(x, corMask)), nbrhood.neighbors);
isRemoved = cellfun(@(x) sum(~ismembc(sort(x), corMask))>nNonVtx, nbrhood.neighbors);
rmvIdx = nbrhood.fa.node_indices(isRemoved);

end