function mgzFile = fv_vol(mgzFile, subjCode, structPath, surfType, loadReg)
% mgzFile = fv_vol(mgzFile, subjCode, structPath, surfType, loadReg)
%
% This function displays the *.mgz file (for volume) in Freeview.
% 
% Inputs: 
%     mgzFile            *.mgz file (with path) [if is empty, 'orig.mgz' for
%                        subjCode will be shown.] (To open a GUI for
%                        selecting files, please use fv_uigetfile.)
%     subjCode           <string> subjCode in SUBJECTS_DIR
%     structPath         <string> the path to SUBJECTS_DIR
%     surfType           <string> the base surface file to be displayed
%                        ('white', 'pial') [porbably should not
%                        be 'inflated' or 'sphere']
%     loadReg            <logical> 1: load 'register.lta' if it is available; 
%                        0: do not load 'register.lta'.
%
% Output:
%     mgzFile            the *.mgz file was displayed
%     Open FreeView to display the mgz (mgh) file
%
% Created by Haiyang Jin (22-Jan-2020)
%
% See also:
% fv_surf; fv_checkrecon; fv_checkreg

if nargin < 1 || isempty(mgzFile) 
    dispMgz = 0;
else
    dispMgz = 1;
    if ischar(mgzFile); mgzFile = {mgzFile}; end
end

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
if dispMgz
    fscmd_mgz = sprintf(repmat(' %s', 1, numel(mgzFile)), mgzFile{:});
    % show with 'register.lta' (created by bbregister)
    fscmd_reg = '';
    thePath = fileparts(mgzFile{1});
    if loadReg
        regFile = fullfile(thePath, 'register.lta');
        if exist(regFile, 'file')
            fscmd_reg = sprintf(':reg=%s', regFile);
        else
            warning('Cannot find registration file: %s.', regFile);
        end
    end
    fscmd_vol = [fscmd_mgz fscmd_reg];
else
    fscmd_vol = '';
end

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
    color.white = 'yellow';
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
fscmd = ['freeview -v' fscmd_orig fscmd_vol fscmd_surf fscmd_other '&'];
system(fscmd);

end