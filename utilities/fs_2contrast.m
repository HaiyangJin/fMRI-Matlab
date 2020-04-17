function contrast = fs_2contrast(fnList, delimiter, conSign)
% contrast = fs_2contrast(fnList, [delimiter='.', conSign='-vs-'])
%
% This function obtains the contrast name from the strings (e.g., a label 
% name when the label name is something like roi.lh.f13.f-vs-o.*label). It
% will obtain the strings around '-vs-'.
%
% Input:
%    fnList          <string> OR <cell string> a list of strings.
%    delimiter       <string> delimiter used to parse the fnList into
%                     multiple parts and contrast name will be one of the
%                     strings. Default is '.', which is for obtaining
%                     contrast from label name. filesep can be used to
%                     obtain contrast name from a path.
%    conSign         <string> contrast sign, i.e., the unique strings in
%                     the contrast names. Default is '-vs-'.  
%
% Output:
%    contrast        <cell string> or <string> a cell of contrast names.
%
% Created by Haiyang Jin (11-Dec-2019)

back2char = 0;
% convert to cell if it is string
if ischar(fnList)
    fnList = {fnList};
    back2char = 1;
end

if ~exist('delimiter', 'var') || isempty(delimiter)
    % defualt is for extracting contrast from label names
    delimiter = '.'; 
end

if ~exist('conSign', 'var') || isempty(conSign)
    conSign = '-vs-';
end

% split the fnList by delimiter
strsCell = cellfun(@(x) strsplit(x, delimiter), fnList, 'uni', false);

% find the string containts '-vs-'
isVs = cellfun(@(x) contains(x, conSign), strsCell, 'uni', false);

% only keep the strings containing '-vs-'
contrastCell = cellfun(@(x, y) x{y}, strsCell, isVs, 'uni', false);

if back2char
    contrast = contrastCell{1};
else
    contrast = contrastCell;
end

end