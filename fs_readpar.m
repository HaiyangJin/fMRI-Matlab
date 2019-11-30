function [tableout, nCondition] = fs_readpar(filename, removeOnset)
% This functions read the paradigm file into matlab as a table
% (Probably too complicated. Needed to be update later.
%
% Created by Haiyang Jin (16/11/2019)

if ~isempty(filename)
    [~,~,ext] = fileparts(filename);
    if ~strcmp(ext, '.par')
        error('The extension of the filename is not "par".');
    end
end

% by default, the OnsetTime will be removed
if nargin < 2 || isempty(removeOnset)
    removeOnset = 1;
end

% load the *.par as a one-dimentional cell
onecell = importdata(filename, ' ');

% convert it to 1*5 cell in each cell
fivecell = arrayfun(@(x) strsplit(x{1}), onecell, 'UniformOutput', false);

% convert it to one cell vector
cellTran = reshape([fivecell{1:end}], 5, []);

tableNames = {'OnsetTime', 'Condition', 'Duration', 'Weight', 'Label'};

% Convert it to table
tmptable = cell2table(cellTran', 'VariableNames', tableNames);
tmptable = tmptable(tmptable.Label ~= "NULL", :);  % remove the baseline

% Create the output table
tableout = table;
if ~removeOnset
    tableout.OnsetTime = str2double(tmptable.OnsetTime);
    tableout.Duration = str2double(tmptable.Duration);
end
tableout.Condition = str2double(tmptable.Condition);
tableout.Weight = str2double(tmptable.Weight);
tableout.Label = tmptable.Label;

tableout = unique(tableout, 'rows'); % remove duplicated rows
tableout = sortrows(tableout, 'Condition'); % sort rows by condition code

nCondition = size(tableout, 1);

end