function overlap_table = fs_labeloverlap(labels, output_path, subjList)
% This function calcualtes the overlapping between two labels
%
% Inputs:
%   labelList           a list (matrix) of label names (could be more than 
%                       2). The labels in the same row will be compared
%                       with each other. (each row is another cell)
%   subjCode            subject code in $SUBJECTS_DIR
%   output_path         where the output file will be saved
% Output
%   overlap_table       a table contains the overlapping information
%
% Created by Haiyang Jin (11/12/2019)

FS = fs_setup;

if nargin < 2 || isempty(output_path)
    output_path = '.';
end
output_path = fullfile(output_path, 'Label_Overlapping');
if ~exist(output_path, 'dir'); mkdir(output_path); end

if nargin < 3 || isempty(subjList)
    subjList = FS.subjList;
elseif ischar(subjList)
    subjList = {subjList};
end

nSubj = FS.nSubj;
nLabelGroup = size(labels, 1);

n = 0;
overlap_str = struct;

for iSubj = 1:nSubj
    
    subjCode = subjList{iSubj};
    labelPath = fullfile(FS.subjects, subjCode, 'label');
    
    
    for iLabel = 1:nLabelGroup
        
        theseLabels = labels{iLabel, :};
        
        nLabel = numel(theseLabels);
        if nLabel < 2
            warning('The number of labels should be more than one.');
            continue;
        end
        
        c = nchoosek(1:nLabel, 2); % combination matrix
        nC = size(c, 1); % number of combinations
        
        for iC = 1:nC
            
            theseLabel = theseLabels(c(iC, :));
            
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
    end
    
end
clear n

overlap_table = struct2table(overlap_str); % convert structure to table
overlap_table = rmmissing(overlap_table, 1); % remove empty rows
writetable(overlap_table, fullfile(output_path, 'Label_Overlapping.xlsx'));

end