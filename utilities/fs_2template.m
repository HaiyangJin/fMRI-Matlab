function outTemplate = fs_2template(filenames, patternCells)
% outTemplate = fs_2template(filenames, patternCells)
%
% This functions tries to identify the template used in the filename. By
% default, it will identify {'fsaverage', 'self'}. This function just to
% test if the strings (e.g., 'fsaverage') are contained in the filenames.
%
% Inputs:
%    filenames          <cell of strings> strings to be checked.
%    patternCells       <cell of strings> the pattern strings. 
%                        {'fsaverage', 'self'} by default.
%
% Output:
%    outTemplate        <cell of strings> the template names for each
%                        filename. 'unkonwn' denotes none of the patterns
%                        were found in the filename. 'multiple' denotes at 
%                        least two of the patterns were found in the
%                        filename.
%
% Example:
% (to identify {'lh', 'rh'}:)
% outTemplate = fs_2template(filenames, {'lh', 'rh'});
%    
% Created by Haiyang Jin (12-Apr-2020)

if nargin < 2 || isempty(patternCells)
    patternCells = {'fsaverage', 'self'};
end
nPattern = numel(patternCells);

if ischar(filenames)
    filenames = {filenames};
end

% whether the pattern is contained in filenames
is = cellfun(@(x) contains(filenames, x), patternCells, 'uni', false);

% create outTemplate with all tempalte being unknown.
outTemplate = repmat({'unknown'}, size(filenames));

% set the outTemplate as corresponding templates
for iP = 1:nPattern
    outTemplate(is{iP}) = patternCells(iP);
end

% set the outTemplate as 'multiple' if more than one pattern was found
outTemplate(sum(vertcat(is{:})) > 1) = {'multiple'};

end