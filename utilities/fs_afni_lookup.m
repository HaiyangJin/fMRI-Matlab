function fs_afni_lookup(trgSubj, hemi, values, surfType, varargin)
% fs_afni_lookup(trgSubj, hemi, values, surfType, varargin)
%
% This function uses AFNI Matlab function (DispIVSurf) to display the
% surface data in 3D (with interaction).
%
% Inputs:
%    trgSubj      <string> the subject code.
%    hemi         <string> or <cell string> hemisphere information. Default
%                  is both hemisphere, i.e., {'lh', 'rh'}.
%    values       <numeric vector> 1xN numeric vector. Values to be
%                  displayed. Default is random numbers.
%    surfType     <string> the surface type. Default is 'inflated'.
%    varargin      other options for DispIVSurf. Following options may help:
%                  .DataRange=[-2 2];
%
% Dependency:
%    AFNI Matlab toolbox.
%
% Created by Haiyang Jin (12-Oct-2020)
%
% See also:
% fs_cvn_lookup

if ~exist('trgSubj', 'var') || isempty(trgSubj)
    trgSubj = 'fsaverage';
end

if ~exist('surfType', 'var') || isempty(surfType)
    surfType = 'inflated';
end

if ~exist('hemi', 'var') || isempty(hemi)
    hemi = {'lh', 'rh'};  % both hemisphere
elseif ischar(hemi)
    hemi = {hemi};
end
whichHemi = sum(find(ismember(hemi, {'lh', 'rh'})));

% load vertices and faces
[vtxCell, faceCell] = fs_cosmo_surfcoor(trgSubj, surfType, numel(hemi)-1);
nVtx = size(vtxCell{whichHemi}, 1);

if ~exist('values', 'var') || isempty(values)
    values = rand(1, nVtx)';
end
if size(values, 2) > 1; values = values'; end

% clim = prctile(values,[1 99]);
% values = max(clim(1), min(values, clim(2)));

% some options for DispIVSurf
opt=struct();
opt.ShowEdge=false;
opt.Dim='3D';

opt = fs_mergestruct(opt, varargin);

% display the surface
DispIVSurf(vtxCell{whichHemi}, faceCell{whichHemi}, 1:nVtx, values,0,opt);
                    
% add title
header = strrep(trgSubj,'_',' ');
title(sprintf('%s %s', surfType, header));

end
