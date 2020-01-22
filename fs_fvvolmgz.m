function fs_fvvolmgz(mgzFile, surfType, loadReg)
% This function displays the *.mgz file (for volume) in Freeview.
% 
% Inputs: 
%     mgzFile            *.mgz file (with path) [if is empty, a window will
%                        open for selecting the *.mgz (mgh) file.
%     surfType           <string> the base surface file to be displayed
%                        ('white', 'pial') [porbably should not
%                        be 'inflated' or 'sphere']
%
% Output:
%      Open FreeView to display the mgz (mgh) file
%
% Created by Haiyang Jin (22-Jan-2020)

if nargin < 2 || isempty(surfType)
    surfType = {'white', 'pial'};
elseif ischar(surfType)
    surfType = {surfType};
end

if nargin < 3 || isempty(loadReg)
    loadReg = 0;
end

% get the path from mgzFile
pathCell = cellfun(@fileparts, mgzFile, 'uni', false);
path = unique(pathCell);  % the path to these files
assert(numel(path) == 1); % make sure all the files are in the same folder
path = path{1}; % convert cell to string

% fscmd for volume mgz
fscmd_mgz = sprintf(['freeview -v' repmat(' %s', 1, numel(mgzFile))], mgzFile{:});

if loadReg
    fscmd_template = sprintf(' %s', templateFile);
else
    fscmd_template = '';
end

fscmd_vol = [fscmd_mgz fscmd_template];

% fscmd for surface
% color table for surface
color.white = 'blue';
color.pial = 'red';
colors = cellfun(@(x) color.(x), surfType, 'uni', false);

surfPath = fullfile(path, '..', 'surf');
hemis = {'lh', 'rh'};
tempColor = repmat(colors, numel(hemis), 1);
tempHemis = repmat(hemis, 1, numel(surfType))';
tempSurf = repmat(surfType, numel(hemis), 1);
surfFile = cellfun(@(x, y) fullfile(surfPath, [x '.' y]), tempHemis, tempSurf(:), 'uni', false);

surfInput = horzcat(surfFile, tempColor(:))';
fscmd_surf = sprintf([' -f' repmat(' %s:edgecolor=%s', 1, numel(surfFile))], surfInput{:});

% fscmd for other
fscmd_other = ' -viewport cor';

% combine commands and run 
fscmd = [fscmd_vol fscmd_surf fscmd_other];
system(fscmd);

end