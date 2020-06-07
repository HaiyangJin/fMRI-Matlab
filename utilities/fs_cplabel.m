function fs_cplabel(srcStructPath, trgStructPath, labelString, strPattern, force)
% fs_cplabel(srcStructPath, trgStructPath, labelString, strPattern, force)
%
% This function copies the labels matching labelString from the source 
% structure path to the target structure path.
%
% Inputs:
%     srcStructPath     <string> the source structure path. Default is
%                        'SUBJECTS_DIR'.
%     trgStructPath     <string> the target structure path
%     labelString       <string> the label strings
%     strPattern        <string> string pattern used to identify subject
%                        folders.
%     force             <logical> used in fs_copyfile.m. [Default is 0 in
%                        fs_copyfile.m]
%
% Output:
%     copy labels to the target path (in the label/ folder)
%
% Created by Haiyang Jin (11-Feb-2020)

if ~exist('srcStructPath', 'var') || isempty(srcStructPath)
    srcStructPath = getenv('SUBJECTS_DIR');
end
if ~exist('labelString', 'var') || isempty(labelString)
    labelString = '*.label';
end 
if ~exist('strPattern', 'var') || isempty(strPattern)
    strPattern = '';
end
if ~exist('force', 'var') || isempty(force) 
    force = '';
end

% obtain the subject list in the source and target directory
[~, srcList] = fs_subjdir(srcStructPath, strPattern, 0);
[~, trgList] = fs_subjdir(trgStructPath, strPattern, 0);

% Create target directories if needed
isAva = ismember(trgList, srcList);
if ~isempty(srcList) && ~all(isAva)
    warning(['SubjCode %s is not found in the target folder. A new folder', ...
        'will be created...'], trgList(isAva));
end

% copy the labels
cellfun(@(x) fs_copyfile(fullfile(srcStructPath, x, 'label', labelString), ...
    fullfile(trgStructPath, x, 'label'), force), ...
    srcList, 'uni', false);

end