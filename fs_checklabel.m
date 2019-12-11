function [allAvail, isAvail] = fs_checklabel(labelList, subjCode)
% This function checks if there is the label(s) for this subject
%
% Inputs:
%    labelList        a list of label(s) (cell)
%    subjCode         subject code in $SUBJECTS_DIR
% Outputs:
%    allAvail         if all the labels are available
%    isAvail          the availability of all labels
% 
% Created by Haiyang Jin (28/11/2019)

% convert to cell if the labelList is a string
if ischar(labelList)
    labelList = {labelList};
end

% FreeSurfer setup
FS = fs_setup;

labelPath = fullfile(FS.subjects, subjCode, 'label');

% the availability of each label
isAvail = (cellfun(@(x) exist(fullfile(labelPath, x), 'file'), labelList));

% availablility of all labels
allAvail = all(isAvail);

end
