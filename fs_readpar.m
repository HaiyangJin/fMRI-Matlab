function tableout = fs_readpar(filename)
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

% load the *.par as a one-dimentional cell
onecell = importdata(filename, ' ');

% convert it to 1*5 cell in each cell
fivecell = arrayfun(@(x) strsplit(x{1}), onecell, 'UniformOutput', false);

% convert it to one cell vector
cellTran = reshape([fivecell{1:end}], 5, []);

tableNames = {'OnsetTime', 'Condition', 'Duration', 'Weight', 'Label'};

% Convert it to table
tableout = cell2table(cellTran', 'VariableNames', tableNames);

% convert strings to numbers
tableout.OnsetTime = str2double(tableout.OnsetTime);
tableout.Condition = str2double(tableout.Condition);
tableout.Duration = str2double(tableout.Duration);
tableout.Weight = str2double(tableout.Weight);

tableout = tableout(tableout.Label ~= "NULL", :);

tableout = sortrows(tableout, 'Condition');


end