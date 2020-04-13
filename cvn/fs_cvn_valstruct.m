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

funcs = {
    @fs_readnifti;
    @load_mgh};
extStr = {
    '.nii', '.nii.gz';
    '.mgh', '.mgz'};

% empty cell for saving data
data = cell(1, 2);

% read data for two hemispehre separately
for iHemi = 1:2
    
    % detect the extension
    isext = any(cellfun(@(x) endsWith(surfCell(iHemi), x), extStr), 2);
    
    % read data with corresponding function
    if ~any(isext)
        data{1, iHemi} = [];
    else
        thisFunc = funcs{isext};
        data{1, iHemi} = thisFunc(surfCell{iHemi});
    end
    
end

% combine the data for two hemispheres
valstruct.data = vertcat(data{:});
% calculate the number of vertices
valstruct.numlh = numel(data{1});
valstruct.numrh = numel(data{2});

end