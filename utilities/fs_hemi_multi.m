function [hemi, nHemi] = fs_hemi_multi(files, forceString)
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
if ischar(files)
    files = {files};
end

if nargin < 2 || isempty(forceString)
    forceString = 1;
end

% remove path if it is included in filenames
[~, nameCell, extCell] = cellfun(@fileparts, files, 'uni', false);
% get filenames for all files
filenames = cellfun(@(x, y) [x y], nameCell, extCell, 'uni', false);

% hemi for each file
hemis = cellfun(@fs_2hemi, filenames, 'UniformOutput', false);

% number of different hemipheres
nHemi = numel(unique(hemis));

if nHemi == 1 && forceString
    hemi = hemis{1};
else
    hemi = hemis;
    if nHemi == 2
        warning('These files are for both hemispheres.');
    end
end

end