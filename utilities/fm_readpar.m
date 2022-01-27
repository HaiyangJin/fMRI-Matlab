function [tableout, nCondition] = fm_readpar(parFile, simpPar)
% [tableout, nCondition] = fm_readpar(parFile, simpPar)
%
% This functions read the paradigm file into matlab as a table
% (Probably too complicated. Needed to be update later).
%
% Inputs:
%    parFile          <string> filename of the par file (with path).
%                      If parFile is not a *.par file (i.e., not ending
%                      with '.par', it will be treated as a path and this
%                      function will try to find the unique *.par file in
%                      that path.
%    simpPar          <logical> 1: simplify the tableout and only keep the
%                      condition numbers, weights and labels (removing 
%                      durations and onset times [default]. 0: save the 
%                      original parfile content as tableout.
%
% Output:
%    tableout         <table> a table contains necesary information in
%                      the paradigm file. 
%    nCondition       <integer> number of conditions.
%
% Created by Haiyang Jin (16-Nov-2019)
%
% See also:
% fm_mkfile

% try to find the unique *.par file if parFile is a path
if ~isempty(parFile)
    [~, ~, theExt] = fileparts(parFile);
    if isempty(theExt)
        tempDir = dir(fullfile(parFile, '*.par'));
        if numel(tempDir) == 1
            parFile = fullfile(parFile, tempDir.name);
        else
            error('Cannot find the unique *.par file at %s', parFile);
        end
    end
end

% by default, the OnsetTime will be removed
if ~exist('simpPar', 'var') || isempty(simpPar)
    simpPar = 1;
end

% load the *.par as a one-dimentional cell
assert(logical(exist(parFile, 'file')), 'Cannot find %s.', parFile);
onecell = importdata(parFile, '');

% convert it to 1*5 cell in each cell
sepcell = arrayfun(@(x) strsplit(x{1}), onecell, 'UniformOutput', false);

% remove empty cells
emptyCell = cellfun(@(x) cellfun(@(y) ~isempty(y), x), sepcell, 'uni', false);
sepcell = cellfun(@(x,y) x(y), sepcell, emptyCell, 'uni', false);

nPerRow = unique(cellfun(@length, sepcell));
assert(nPerRow >= 3 && nPerRow <= 5, ...
    'Please make sure the par file is prepared appropriately.');

% convert it to one cell vector
cellTran = reshape([sepcell{:}], nPerRow, []);

if nPerRow == 3
    cellTran = vertcat(cellTran, repmat({'1'}, 1, size(cellTran, 2)), cellTran(2,:));
elseif nPerRow == 4
    cellTran = vertcat(cellTran, cellTran(2,:));
end

tableNames = {'OnsetTime', 'Condition', 'Duration', 'Weight', 'Label'};

% Convert it to table
tmptable = cell2table(cellTran', 'VariableNames', tableNames);

if simpPar
    tmptable = tmptable(tmptable.Condition ~= "0", :);  % remove the baseline
end

% Create the output table
tableout = table;
if ~simpPar
    tableout.OnsetTime = str2double(tmptable.OnsetTime);
end
tableout.Condition = str2double(tmptable.Condition);
if ~simpPar
    tableout.Duration = str2double(tmptable.Duration);
end
tableout.Weight = str2double(tmptable.Weight);
tableout.Label = tmptable.Label;

if simpPar
    tableout = unique(tableout, 'rows'); % remove duplicated rows
    tableout = sortrows(tableout, 'Condition'); % sort rows by condition code
end

nCondition = size(tableout, 1);

end