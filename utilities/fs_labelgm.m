function gmTable = fs_labelgm(labelList, subjList)
% [gmTable, GlobalMax] = fs_labelgm(labelList, subjList)
%
% This function reads the global maxima file for the label file. They
% should be stored in the same directory (i.e., in the label/ folder) and
% share the same filename (but different extensions; '.label' for the label
% and '.gm' for the globalmaxima file). Note: The vertex index stored in 
% *.gm file is the vertex number in Matlab. 
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
gmSCell = cellfun(@(x, y) labelgm(x, y), Label, SubjCode, 'uni', false);

if numel(gmSCell) == 1
    gmSTable = struct2table(gmSCell{1}, 'AsArray', 1);
else
    gmSTable = struct2table(vertcat(gmSCell{:}));
end

% make the output table
gmTable = horzcat(table(Label, SubjCode), gmSTable);

end

%% read the global maxima for that label and that subject code
function gmStruct = labelgm(labelFn, subjCode)

% create the gm filename based on label filename
gmFn = strrep(labelFn, '.label', '.gm');

% add the path if needed
if ~exist(gmFn, 'file')
    gmFn = fullfile(getenv('SUBJECTS_DIR'), subjCode, 'label', gmFn);
end

if ~exist(gmFn, 'file')
    gmStruct.gm = NaN;
    gmStruct.MNI305 = [NaN NaN NaN];
    gmStruct.Talairach = [NaN NaN NaN];
else
    % read the file
    gmStruct.gm = str2double(fs_readtext(gmFn)); % from FS to matlab
    labelMat = fs_readlabel(labelFn, subjCode);
    isgm = labelMat(:, 1) == gmStruct.gm;
    % coordiantes in RAS, MNI305(fsaverage) and Talairach space
    RAS = labelMat(isgm, 2:4);
    assert(~isempty(RAS), 'The global maxima is not inclued in the label!');
    gmStruct.MNI305 = fs_self2fsavg(RAS, subjCode);
    gmStruct.Talairach = mni2tal(gmStruct.MNI305);
end

end