function outTemplate = fs_2template(filenames, patternCells, defaultStr)
% outTemplate = fs_2template(filenames, [patternCells={'fsaverage', 'self'},...
%                            defaultOut={'unknown'}])
%
% This functions tries to identify the template used in the filename. By
% default, it will identify {'fsaverage', 'self'}. This function just to
% test if the strings (e.g., 'fsaverage') are contained in the filenames.
%
% Inputs:
%    filenames          <cell of strings> strings to be checked.
%    patternCells       <cell of strings> the pattern strings.
%                        {'fsaverage', 'self'} by default.
%    defaultStr         <string> the default out strings if no patterns are
%                        identified in filenames ['unknown' by default].
%
% Output:
%    outTemplate        <cell of strings> the template names for each
%                        filename. 'unkonwn' denotes none of the patterns
%                        were found in the filename. 'multiple' denotes at
%                        least two of the patterns were found in the
%                        filename.
%
% Example:
% (to identify {'lh', 'rh'})
% outTemplate = fs_2template(filenames, {'lh', 'rh'});
%
% Created by Haiyang Jin (12-Apr-2020)

if ~exist('patternCells', 'var') || isempty(patternCells)
    patternCells = {'fsaverage', 'self'};
end
nPattern = numel(patternCells);

if ~exist('', 'var') || isempty(defaultStr)
    defaultStr = {'unknown'};
elseif ischar(defaultStr)
    defaultStr = {defaultStr};
end

if ischar(filenames)
    filenames = {filenames};
end

% whether the pattern is contained in filenames
isAva = cellfun(@(x) contains(filenames, x), patternCells, 'uni', false);

% create outTemplate with all tempalte being unknown.
outTemplate = repmat(defaultStr, size(filenames));

% set the outTemplate as corresponding templates
for iP = 1:nPattern
    outTemplate(isAva{iP}) = patternCells(iP);
end

% set the outTemplate as 'multiple' if more than one pattern was found
outTemplate(sum(vertcat(isAva{:})) > 1) = {'multiple'};

if numel(outTemplate) == 1;
    outTemplate = outTemplate{1};
end

end