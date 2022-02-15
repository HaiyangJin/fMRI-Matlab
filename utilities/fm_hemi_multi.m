function [hemi, nHemi] = fm_hemi_multi(files, forceString, fnOnly)
% [hemi, nHemi] = fm_hemi_multi(files, forceString, fnOnly)
%
% This function determine the hemispheres based on the filenames (if 'lh'
% or 'rh' is included in the filename).
%
% Inputs:
%    filenames         <cell> or <str> filenames (with out path).
%    forceString       <boo> force the output to be string if the
%                        length of filenames is 1.
%    fnOnly            <boo> 1 [default]: only check the filename; 0:
%                        also check the path.
%
% Outputs:
%    hemi              <cell str> could be a cell of 'lh' and 'rh'. Or a 
%                       string based on forceString.
%    nHemi             <int> number of different hemispheres for filenames.
%
% Created by Haiyang Jin (1-Dec-2019)
%
% See also:
% fm_2hemi

if nargin < 1
    fprintf('Usage: [hemi, nHemi] = fm_hemi_multi(files, forceString, fnOnly);\n');
    return;
end

% convert the filenames to a cell if it is a string
if ischar(files)
    files = {files};
end

if ~exist('forceString', 'var') || isempty(forceString)
    forceString = 1;
end

if ~exist('fnOnly', 'var') || isempty(fnOnly)
    fnOnly = 1;
end

if fnOnly
    % remove path if it is included in filenames
    [~, nameCell, extCell] = cellfun(@fileparts, files, 'uni', false);
    % get filenames for all files
    filenames = cellfun(@(x, y) [x y], nameCell, extCell, 'uni', false);
else
    filenames = files;
end

% hemi for each file
hemis = cellfun(@(x) fm_2hemi(x, fnOnly), filenames, 'UniformOutput', false);

% number of different hemipheres
nHemi = numel(unique(hemis));

if nHemi == 1 && forceString
    hemi = hemis{1};
else
    hemi = hemis;
    if nHemi == 2
        warning('These files are not for the same hemisphere.');
    end
end

end