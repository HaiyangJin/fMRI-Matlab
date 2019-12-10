function [labelSumTable, labelSumLongTable] = fs_sumlabelinfo(labelNames, outputPath)
% This function gathers information of "all" labels
%
% Inputs:
%    labelNames       label names or parts of label names that could be read
%                     by fs_labeldir.m
%    outputPath       where the output files will be saved
% Output:
%    labelSumTable     
%    
%
% Created by Haiyang Jin (9/12/2019)

if nargin < 2 || isempty(outputPath)
    outputPath = fullfile('.', 'Label_Summary');
end
if ~exist(outputPath, 'dir'); mkdir(outputPath); end

% FreeSurfer setup
FS = fs_setup;

subjList = FS.subjList;
nSubj = FS.nSubj;

labelStruct = struct([]);
labelStructlong = struct([]);
n = 0;

% get info for each subject
for iSubj = 1:nSubj
    
    thisSubj = subjList{iSubj};
    
    thisLabelPath = fullfile(FS.subjects, thisSubj, 'label');
    
    % List all files matching labelNames
    labelDir = fs_labeldir(thisSubj, labelNames);
    
    nLabel = length(labelDir);
    
    labelStruct(iSubj).SubjCode = thisSubj;
    
    
    for iLabel = 1:nLabel
        
        thisLabel = labelDir(iLabel).name;
        
        [~, nVtx] = fs_readlabel(fullfile(thisLabelPath, thisLabel));
  
        tempLabel = strrep(thisLabel, '.', '0');
        tempLabel = strrep(tempLabel, '-', 'T');
        
        labelStruct(iSubj).(tempLabel) = nVtx;
        
        n = n + 1;
        labelStructlong(n).SubjCode = thisSubj;
        labelStructlong(n).label = thisLabel;
        labelStructlong(n).nVertice = nVtx;
        
        labelInfo = strsplit(thisLabel, '.');
        labelStructlong(n).hemi = labelInfo{2};
        labelStructlong(n).sig = labelInfo{3};
        labelStructlong(n).Contrast = labelInfo{4};
        
        if length(labelInfo) > 5
            labelStructlong(n).ffa = labelInfo{5};
        end
    end
end

labelTable = struct2table(labelStruct);

labelVarNames = cellfun(@(x) strrep(x, '0', '.'), labelTable.Properties.VariableNames, ...
    'UniformOutput', false);
labelVarNames = cellfun(@(x) strrep(x, 'T', '-'), labelVarNames, 'UniformOutput', false);

labelSumTable = [cell2table(labelVarNames, 'VariableNames', labelTable.Properties.VariableNames); labelTable];

% output filename
file_output = fullfile(outputPath, 'Label_Summary.xlsx');
warning('off','MATLAB:xlswrite:AddSheet');  % turn off warning
% wide table
writetable(labelSumTable, file_output,...
    'Sheet', 'Wide_format', 'WriteVariableNames', false);
% long table
labelSumLongTable= struct2table(labelStructlong);
writetable(labelSumLongTable, file_output,...
    'Sheet', 'Long_format');

end

