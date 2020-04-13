function contrast = fs_2contrast(fnList)
% contrast = fs_2contrast(fnList)
%
% This function obtains the contrast name from the strings (e.g., a label 
% name when the label name is something like roi.lh.f13.f-vs-o.*label). It
% will obtain the strings around '-vs-'.
%
% Input:
%    labelList          <string> a string.
%                    OR <string cell> a list of strings.
%
% Output:
%    contrast           <string cell> a cell of contrast names.
%
% Created by Haiyang Jin (11-Dec-2019)

back2char = 0;
% convert to cell if it is string
if ischar(fnList)
    fnList = {fnList};
    back2char = 1;
end

% transponse if there is only one row
if size(fnList, 1) == 1
    fnList = fnList';
end

nLabel = numel(fnList);
contrastCell = cell(size(fnList));

% obtain the contrast name for each string
for iLabel = 1:nLabel
    
    labelName = fnList{iLabel};
    
    % find the "." to identify the contrast name
    [conStart, conEnd] = regexp(labelName, '\w*\-vs\-\w*'); % pattern (word-vs-word)
    contrastCell(iLabel) = {labelName(conStart:conEnd)};

end

if back2char
    contrast = contrastCell{1};
else
    contrast = contrastCell;
end

end