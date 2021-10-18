function roiMask = fs_label2mask(labelFn, subjCode, nVtxTotal)
% roiMask = fs_label2mask(labelFn, subjCode, nVtxTotal)
%
% This function converts a label file into a binary mask.
%
% Inputs:
%    labelFn       <string> the label filenamel.
%    subjCode      <string> subject code.
%    nVtxTotal     <integer> the total number of vertices (for that
%                   hemisphere). Default is the vertex number obtained from
%                   ?h.white.
%
% Output:
%    roiMask       <logical array> a binary mask.
%
% Created by Haiyang Jin (26-May-2020)

% obtain the default vertex number
if ~exist('nVtxTotal', 'var') || isempty(nVtxTotal)
    surfFn = [fm_2hemi(labelFn) '.white'];
    nVtxTotal = size(fs_readsurf(surfFn, subjCode), 1);
end

% load the label file
labelMat = fs_readlabel(labelFn, subjCode);

% by default, all vertices are not in the mask
roiMask = false(nVtxTotal, 1);

% create mask for the label
if ~isempty(labelMat)
    roiMask(labelMat(:, 1)) = true;
end

end