function contrast = fs_label2contrast(labelList)
% This function obtains the contrast name from the label name when the
% label name is something like roi.lh.f13.f-vs-o.*label
%
% Input:
%    labelList          a list of label names
% Output:
%    contrast_cell      a cell of contrast names
%
% Created by Haiyang Jin (11/12/2019)

back2char = 0;
% convert to cell if it is string
if ischar(labelList)
    labelList = {labelList};
    back2char = 1;
end

% transponse if there is only one row
if size(labelList, 1) == 1
    labelList = labelList';
end

nLabel = numel(labelList);
contrast_cell = cell(size(labelList));

% obtain the contrast name for each label
for iLabel = 1:nLabel
    
    labelName = labelList{iLabel};
    
    % find the "." to identify the contrast name
    conStrPosition = strfind(labelName, '.');
    contrast_cell(iLabel) = {labelName(conStrPosition(3)+1:conStrPosition(4)-1)};

end

if back2char
    contrast = contrast_cell{1};
else
    contrast = contrast_cell;
end


