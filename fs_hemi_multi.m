function [hemi, nHemi] = fs_hemi_multi(filenames, forceString)
% This function determine the hemispheres based on the filenames (if 'lh'
% or 'rh' is included in the filename).
%
% Inputs:
%     filenames         <cell> or <string> filenames (with out path)
%     forceString       <logical> force the output to be string if the
%                       length of filenames is 1
%
% Outputs:
%     hemi              could be a cell of 'lh' and 'rh'. Or a string based
%                       on forceString
%     nHemi             number of different hemispheres for filenames
%
% Created by Haiyang Jin (1-Dec-2019)

% convert the filenames to a cell if it is a string
if ischar(filenames)
    filenames = {filenames};
end

if nargin < 2 || isempty(forceString)
    forceString = 1;
end

% hemi for each file
hemis = cellfun(@fs_hemi, filenames, 'UniformOutput', false);

% number of different hemipheres
nHemi = numel(unique(hemis));

if nHemi == 1 && forceString
    hemi = hemis{1};
else
    hemi = hemis;
    warning('These files are for both hemispheres.');
end

end