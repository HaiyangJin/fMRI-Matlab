function valstruct = fs_cvn_valstruct(surfCell)
% valstruct = fs_cvn_valstruct(surfCell)
%
% This function reads surfCell and make it suitable for fs_cvn_lookuplmv.m
% or cvnlookupimages.m.
%
% Input:
%    surfCell      <string cell> 1 x 2 cell. The first cell is the filename
%                   of data on the left hemisphere (with path); the second
%                   cell is the filename of data on the right hemisphere.
%
% Output:
%    valstruct     <struct> struct used for cvnlookupimages.m.
%
% Created by Haiyang Jin (13-Apr-2020)

valstruct = struct;

% read the file in surfCell
surfData = cellfun(@fs_readfunc, surfCell, 'uni', false);

% combine the data for two hemispheres
valstruct.data = vertcat(surfData{:});
% calculate the number of vertices
valstruct.numlh = numel(surfData{1});
valstruct.numrh = numel(surfData{2});

end