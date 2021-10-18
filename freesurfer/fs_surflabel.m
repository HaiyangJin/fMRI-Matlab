function [outTable, fscmd] = fs_surflabel(sessList, labelList, anaList, thmin, outPath)
% [outTable, fscmd] = fs_surflabel(sessList, labelList, anaList, thmin, outPath)
%
% This function gathers information of the label files via mri_surfcluster.
%
% Inputs:
%    sessList        <cell string> a list of session codes.
%    labelList       <cell string> a list of label names.
%    anaList         <cell string> a list of analysis names. This will be
%                     used to read the corresponding sig.nii.gz.
%    thmin           <numeric> the minimal threshold. Default is [], which
%                     will use the default in fs_surfcluster.m (i.e.,1.3).
%    outPath         <string> where the outputs are saved.
%
% Output:
%    outTable        <table> information about all the available label file
%                     information.
%    fscmd           <cell string> all the FreeSurfer commands used.
%
% Created by Haiyang Jin (26-Apr-2020)

if ~exist('thmin', 'var') || isempty(thmin)
    thmin = [];
end
if ~exist('outPath', 'var') || isempty(outPath)
    outPath = pwd;
end

% convert to cell if it is string(char)
if ischar(sessList); sessList = {sessList}; end
if ischar(labelList); labelList = {labelList}; end
if ischar(anaList); anaList = {anaList}; end

% number of session codes and label names
nSess = numel(sessList);
nLabel = numel(labelList);
nAna = numel(anaList);

tableCell = cell(nSess, nLabel, nAna);
fscmdCell = cell(nSess, nLabel, nAna);

for iSess = 1:nSess
    
    % this session code4
    thisSess = sessList{iSess};
    
    for iLabel = 1:nLabel
        
        % this label name
        thisLabel = labelList{iLabel};
        
        % obtain the hemisphere information
        theHemi = fm_2hemi(thisLabel);
        
        % only keep the analysis names for this hemisphere
        isAna = contains(anaList, theHemi);
        theAnaList = anaList(isAna);
        
        % number of the correspoonding analysis names
        nTheAna = numel(theAnaList);
        
        for iAna = 1:nTheAna
            
            % this analysis name
            thisAna = theAnaList{iAna};
            
            % run mri_surfcluster
            [tableCell{iSess, iLabel, iAna}, fscmdCell{iSess, iLabel, iAna}] ...
                = fs_surfcluster(thisSess, thisAna, thisLabel, '', thmin, outPath);
            
        end % iAna
    end % iLabel
    
end % iSess

% convert cell to table
outTable = vertcat(tableCell{:});
fscmd = vertcat(fscmdCell(:));
fscmd(cellfun(@isempty, fscmd)) = [];

% save the outTable as a csv file
outFn = 'labelInfo.csv';
writetable(outTable, fullfile(outPath, outFn));

end