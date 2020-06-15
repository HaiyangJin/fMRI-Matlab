function [gmTable, GlobalMax] = fs_labelgm(labelList, subjList)
% [gmTable, GlobalMax] = fs_labelgm(labelList, subjList)
%
% This function reads the global maxima file for the label file. They
% should be stored in the same directory (i.e., in the label/ folder) and
% share the same filename (but different extensions; '.label' for the label
% and '.gm' for the globalmaxima file).
%
% Inputs:
%    labelList       <cell string> list of the label files (with or without
%                     path). If path is included in labelFn, 'subjCode'
%                     will be ignored. 
%    subjList        <cell string> subject code in struPath. 
%
% Output:
%    gmTable         <table> the vertex index of the global maxima for each
%                     label and subject.
%    GlobalMax       <integer> a vector of the vertex indices of the global
%                     maxima.
%
% Created by Haiyang Jin (15-Jun-2020)

if ischar(labelList); labelList = {labelList}; end
if ischar(subjList); subjList = {subjList}; end 

% create all combinations of label and subject
[tempLabel, tempSubj] = ndgrid(labelList, subjList);
Label = tempLabel(:);
SubjCode = tempSubj(:);

% obtain the indices
GlobalMax = cellfun(@(x, y) labelgm(x, y), Label, SubjCode);

% make the output table
gmTable = table(Label, SubjCode, GlobalMax);

end

%% read the global maxima for that label and that subject code
function gm = labelgm(labelFn, subjCode)

% create the gm filename based on label filename
gmFn = strrep(labelFn, '.label', '.gm');

% add the path if needed
if ~exist(gmFn, 'file')
    gmFn = fullfile(getenv('SUBJECTS_DIR'), subjCode, 'label', gmFn);
end

if ~exist(gmFn, 'file')
    gm = NaN;
else
    % read the file
    gm = str2double(fs_readtext(gmFn));
end

end