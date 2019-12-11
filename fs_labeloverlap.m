function overlap_table = fs_labeloverlap(labelList, subjCode, output_path)
% This function calcualtes the overlapping between two labels
%
% Inputs:
%   labelList           a list of label names (could be more than 2)
%   subjCode            subject code in $SUBJECTS_DIR
%   output_path         where the output file will be saved
% Output
%   overlap_table       a table contains the overlapping information
%
% Created by Haiyang Jin (11/12/2019)

if nargin < 3 || isempty(output_path)
    output_path = '.';
end
output_path = fullfile(output_path, 'Label_Overlapping');
if ~exist(output_path, 'dir'); mkdir(output_path); end

nLabel = numel(labelList);
if nLabel < 2
    error('The number of labels should be more than one.');
end

FS = fs_setup;
labelPath = fullfile(FS.subjects, subjCode, 'label');

c = nchoosek(1:nLabel, 2); % combination matrix
nC = size(c, 1); % number of combinations

overlap_str = struct;
n = 0;
for iC = 1:nC
    
    theseLabel = labelList(c(iC, :));
    
    % skip if at least one label is not available
    if ~fs_checklabel(theseLabel, subjCode)
        continue;
    end
    
    % load the two label files 
    mat_cell = cellfun(@(x) fs_readlabel(fullfile(labelPath, x)), theseLabel, 'UniformOutput', false);
    
    % check if there is overlapping between the two labels
    mat_label1 = mat_cell{1};
    mat_label2 = mat_cell{2};
    isoverlap = ismember(mat_label1, mat_label2);
    overlapVer = mat_label1(isoverlap(:, 1));
    nOverVer = numel(overlapVer);
    
    % save information to the structure
    n = n + 1;
    overlap_str(n).SubjCode = {subjCode};
    overlap_str(n).Label = theseLabel;
    overlap_str(n).nOverlapVer = nOverVer;
    overlap_str(n).OverlapVer = {overlapVer'};
    
end
clear n

overlap_table = struct2table(overlap_str); % convert structure to table
overlap_table = rmmissing(overlap_table, 1); % remove empty rows
writetable(overlap_table, fullfile(output_path, 'Label_Overlapping.xlsx'));

end