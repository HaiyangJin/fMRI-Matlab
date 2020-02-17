function fs_cplabel(sourceStructPath, targetStructPath, labelString, force)
% This function copies the labels matching labelString from the source 
% structure path to the target structure path.
%
% Inputs:
%     sourceStructPath     <string> the source structure path
%     targetStructPath     <string> the target structure path
%     labelString          <string> the label strings
%
% Output:
%     copy labels to the target path (in the label/ folder)
%
% Created by Haiyang Jin (11-Feb-2020)

if nargin < 3 || isempty(labelString)
    labelString = '*.label';
end 
if nargin < 4 
    force = '';
end

source = fs_subjdir(sourceStructPath);
target = fs_subjdir(targetStructPath);

isAva = ismember(source.subjList, target.subjList);

if target.nSubj > 0 && ~all(isAva)
    warning('SubjCode %s is not found in the target folder.', ...
        source.subjList(isAva));
end

cellfun(@(x) fs_copyfile(fullfile(sourceStructPath, x, 'label', labelString), ...
    fullfile(targetStructPath, x, 'label'), force), ...
    source.subjList, 'uni', false);

end