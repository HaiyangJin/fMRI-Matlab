function [labelSumTable, labelSumLongTable] = fs_sumlabelinfo(labelNames, outputPath)
% This function gathers information for "all" labels
%
% Inputs:
%    labelNames         label names or parts of label names that could be 
%                       read by fs_labeldir.m (But the filename of label 
%                       should be something like "roi.*.*-vs-*.*.label"
%    outputPath         where the output files will be saved
% Output:
%    labelSumTable      The wide format of the information
%    labelSumLongTable  
%    
% Created by Haiyang Jin (9-Dec-2019)

if nargin < 2 || isempty(outputPath)
    outputPath = fullfile('.');
end
isSave = ~strcmp('none', outputPath);  % do not save files if outputPath is 'none'
outputPath = fullfile(outputPath, 'Label_Summary');
if ~exist(outputPath, 'dir'); mkdir(outputPath); end

% FreeSurfer setup
FS = fs_subjdir;

subjList = FS.subjList;
nSubj = FS.nSubj;

% create empty data structures for saving data
labelStruct = struct([]);  % wide format
labelStructlong = struct([]);  % long format
n = 0;

% get info for each subject
for iSubj = 1:nSubj
    
    subjCode = subjList{iSubj};
        
    % List all files matching labelNames
    labelDir = fs_labeldir(subjCode, labelNames);
    
    nLabel = numel(labelDir);  % number of labels
    
    labelStruct(iSubj).SubjCode = subjCode;
    
    
    for iLabel = 1:nLabel
        
        thisLabel = labelDir(iLabel).name;
        
        % number of vtx in this label
        [~, nVtx] = fs_readlabel(thisLabel, subjCode);
        
        % replace some specifal strings (they could not be used as column
        % names in structure
        tempLabel = strrep(thisLabel, '.', '9');
        tempLabel = strrep(tempLabel, '-', 'T');
        
        % wide format
        labelStruct(iSubj).(tempLabel) = nVtx;
        
        % long format
        n = n + 1;
        labelStructlong(n).SubjCode = subjCode;
        labelStructlong(n).label = thisLabel;
        labelStructlong(n).nVertice = nVtx;
        
        % split the label name by '.' to gather the information
        labelInfo = strsplit(thisLabel, '.');
        
        % only record the information if there is enough information
        if numel(labelInfo) > 4
            labelStructlong(n).hemi = labelInfo{2};
            labelStructlong(n).sig = labelInfo{3};
            labelStructlong(n).Contrast = labelInfo{4};
        end
        if numel(labelInfo) > 5
            labelStructlong(n).ffa = labelInfo{5};
        end
    end
end

% Wide format
% convert the structre to table for wide format
labelTable = struct2table(labelStruct);
% change back the specifal strings (rename the table column names
labelVarNames = cellfun(@(x) strrep(x, '9', '.'), labelTable.Properties.VariableNames, ...
    'UniformOutput', false);
labelVarNames = cellfun(@(x) strrep(x, 'T', '-'), labelVarNames, 'UniformOutput', false);

% save the label names as another table and combine it with the label
% information
labelSumTable = [cell2table(labelVarNames, 'VariableNames', labelTable.Properties.VariableNames); labelTable];
labelSumLongTable= struct2table(labelStructlong);

if isSave
    % output filename
    outputFile = fullfile(outputPath, 'Label_Summary.xlsx');
    warning('off','MATLAB:xlswrite:AddSheet');  % turn off warning
    % wide table
    writetable(labelSumTable, outputFile,...
        'Sheet', 'Wide_format', 'WriteVariableNames', false);
    % long table
    writetable(labelSumLongTable, outputFile,...
        'Sheet', 'Long_format');
end

end

