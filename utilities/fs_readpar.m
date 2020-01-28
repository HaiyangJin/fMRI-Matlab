function [tableout, nCondition] = fs_readpar(parFile, cleanPar)
% This functions read the paradigm file into matlab as a table
% (Probably too complicated. Needed to be update later.
%
% Created by Haiyang Jin (16-Nov-2019)

if ~isempty(parFile)
    [~,~,ext] = fileparts(parFile);
    if ~strcmp(ext, '.par')
        error('The extension of the filename is not "par".');
    end
end

% by default, the OnsetTime will be removed
if nargin < 2 || isempty(cleanPar)
    cleanPar = 1;
end

% load the *.par as a one-dimentional cell
assert(logical(exist(parFile, 'file')), 'Cannot find %s.', parFile);
onecell = importdata(parFile, '');

% convert it to 1*5 cell in each cell
fivecell = arrayfun(@(x) strsplit(x{1}), onecell, 'UniformOutput', false);

% remove empty cells
emptyCell = cellfun(@(x) cellfun(@(y) ~isempty(y), x), fivecell, 'uni', false);
fivecell = cellfun(@(x,y) x(y), fivecell, emptyCell, 'uni', false);

% convert it to one cell vector
cellTran = reshape([fivecell{:}], 5, []);

tableNames = {'OnsetTime', 'Condition', 'Duration', 'Weight', 'Label'};

% Convert it to table
tmptable = cell2table(cellTran', 'VariableNames', tableNames);

if cleanPar
    tmptable = tmptable(tmptable.Label ~= "NULL", :);  % remove the baseline
end

% Create the output table
tableout = table;
if ~cleanPar
    tableout.OnsetTime = str2double(tmptable.OnsetTime);
    tableout.Duration = str2double(tmptable.Duration);
end
tableout.Condition = str2double(tmptable.Condition);
tableout.Weight = str2double(tmptable.Weight);
tableout.Label = tmptable.Label;

if cleanPar
    tableout = unique(tableout, 'rows'); % remove duplicated rows
    tableout = sortrows(tableout, 'Condition'); % sort rows by condition code
end

nCondition = size(tableout, 1);

end