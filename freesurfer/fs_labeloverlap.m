function overlapTable = fs_labeloverlap(labels, subjList, outPath)
% overlapTable = fs_labeloverlap(labels, subjList, outPath)
%
% This function calcualtes the overlapping between every two labels.
%
% Inputs:
%   labels            <cell str> a list (matrix) of label names (can be 
%                      more than 2). The labels in the same row will be 
%                      compared with each other. (each row is another cell).
%   subjList          <cell str> subject code in $SUBJECTS_DIR.
%   outPath           <str> where the output file will be saved. If it is
%                      'none', no output files will be saved. 
%
% Output
%   overlapTable      <table> a table contains the overlapping information
%
% Created by Haiyang Jin (11/12/2019)

if nargin < 1
    fprintf('Usage: overlapTable = fs_labeloverlap(labels, subjList, varargin);\n');
    return;
end
if ischar(subjList); subjList = {subjList}; end
nSubj = numel(subjList);

if ~exist('outPath', 'var') || isempty(outPath)
    outPath = '.';
end
outPath = fullfile(outPath, 'Label_Overlapping');
if ~strcmp(outPath, 'none') && ~exist(outPath, 'dir'); mkdir(outPath); end

nLabelGroup = size(labels, 1);

n = 0;
overlapStr = struct;

for iSubj = 1:nSubj
    
    subjCode = subjList{iSubj};
%     labelPath = fullfile(FS.subjects, subjCode, 'label');
    
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
            matCell = cellfun(@(x) fs_readlabel(x, subjCode), theseLabel, 'uni', false);
            
            % check if there is overlapping between the two labels
            matLabel1 = matCell{1};
            matLabel2 = matCell{2};
            isoverlap = ismember(matLabel1, matLabel2);
            overlapVer = matLabel1(isoverlap(:, 1));
            nOverVer = numel(overlapVer);
            
            % save information to the structure
            n = n + 1;
            overlapStr(n).SubjCode = {subjCode};
            overlapStr(n).Label = theseLabel;
            overlapStr(n).nOverlapVer = nOverVer;
            overlapStr(n).Area = fs_vtxarea(overlapVer, subjCode, ...
                fm_hemi_multi(theseLabel, 1));
            overlapStr(n).OverlapVer = {overlapVer'};
            
        end
    end
    
end
clear n

overlapTable = struct2table(overlapStr); % convert structure to table
overlapTable = rmmissing(overlapTable, 1); % remove empty rows
if ~strcmp(outPath, 'none')
    writetable(overlapTable, fullfile(outPath, 'Label_Overlapping.xlsx'));
end

end