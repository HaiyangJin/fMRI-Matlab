function valstruct = fs_cvn_valstruct(surfCell, hemi)
% valstruct = fs_cvn_valstruct(surfCell)
%
% This function reads surfCell and make it suitable for fs_cvn_lookuplmv.m
% or cvnlookupimages.m.
%
% Input:
%    surfCell      <string cell> 1 x 2 cell. The first cell is the filename
%                   of data on the left hemisphere (with path); the second
%                   cell is the filename of data on the right hemisphere.
%    hemi          <string> if surfCell is only for hemisphere data, 'hemi'
%                   is the hemisphere information ['lh' or 'rh'].
%
% Output:
%    valstruct     <struct> struct used for cvnlookupimages.m.
%
% Created by Haiyang Jin (13-Apr-2020)

% if hemi is not empty
if exist('hemi', 'var')
    if strcmp(hemi, 'lh')
        surfCell = {surfCell, ''};
    elseif strcmp(hemi, 'rh')
        surfCell = {'', surfCell};
    else
        error('''hemi'' has to be ''lh'' or ''rh'' (not %s).', hemi);
    end
end

valstruct = struct;

% read the file in surfCell
surfData = cellfun(@fs_readfunc, surfCell, 'uni', false);

% combine the data for two hemispheres
valstruct.data = vertcat(surfData{:});

% calculate the number of vertices
valstruct.numlh = numel(surfData{1});
valstruct.numrh = numel(surfData{2});

end