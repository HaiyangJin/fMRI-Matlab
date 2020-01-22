function mgzFile = fs_fvvol(mgzFile, subjCode, structPath, surfType, loadReg)
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

if ischar(mgzFile); mgzFile = {mgzFile}; end

if nargin < 2 %|| isempty(subjCode)
    subjCode = '';
end

if nargin < 3 || isempty(structPath)
    structPath = getenv('SUBJECTS_DIR');
end

if nargin < 4 || isempty(surfType)
    surfType = {'white', 'pial'};
elseif ischar(surfType)
    surfType = {surfType};
end

if nargin < 5 || isempty(loadReg)
    loadReg = 0;
end

% fscmd for volume mgzFile
fscmd_mgz = sprintf(repmat(' %s', 1, numel(mgzFile)), mgzFile{:});
% show with 'register.lta' (created by bbregister)
fscmd_reg = '';
thePath = fileparts(mgzFile{1});
if loadReg
    regFile = fullfile(thePath, 'register.lta');
    if exist(regFile, 'file')
        fscmd_reg = sprintf(':reg=%s', regFile);
    end
end
fscmd_vol = [fscmd_mgz fscmd_reg];

% get the structPath for this subjCode

if (isempty(subjCode) || isempty(structPath))
    subjPath = fullfile(thePath, '..');
else
    subjPath = fullfile(structPath, subjCode);
end
origFile = fullfile(subjPath, 'mri', 'orig.mgz');

if  ~exist(origFile, 'file')
    % only show the selected file
    fscmd_orig = '';
    fscmd_surf = '';
else
    % also show orig.mgz and ?h.pial and ?h.white
    
    % fscmd for volume orig
    fscmd_orig = sprintf(' %s:visible=0', origFile);
    
    % fscmd for surface
    % color table for surface
    color.white = 'blue';
    color.pial = 'red';
    colors = cellfun(@(x) color.(x), surfType, 'uni', false);
    
    surfPath = fullfile(subjPath, 'surf');
    hemis = {'lh', 'rh'};
    tempColor = repmat(colors, numel(hemis), 1);
    tempHemis = repmat(hemis, 1, numel(surfType))';
    tempSurf = repmat(surfType, numel(hemis), 1);
    surfFile = cellfun(@(x, y) fullfile(surfPath, [x '.' y]), tempHemis, tempSurf(:), 'uni', false);
    
    surfInput = horzcat(surfFile, tempColor(:))';
    fscmd_surf = sprintf([' -f' repmat(' %s:edgecolor=%s', 1, numel(surfFile))], surfInput{:});
    
end

% fscmd for other
fscmd_other = ' -viewport cor';

% combine commands and run 
fscmd = ['freeview -v' fscmd_orig fscmd_vol fscmd_surf fscmd_other];
system(fscmd);

end