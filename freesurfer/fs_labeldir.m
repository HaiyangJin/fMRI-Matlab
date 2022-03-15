function labelDir = fs_labeldir(subjCode, labelNames)
% labelDir = fs_labeldir(subjCode, labelNames)
%
% This function list all labels for the label names
%
% Inputs:
%    subjCode        subject code in $SUBJECTS_DIR
%    labelnames      could be a cell contains the full filenames of all
%                    labels; 
%                    or could be a cell contains only parts of the
%                    labels (e.g., {'roi.face*.label', 'roi.word*.label'});
%                    or could be a string.
% Output:
%     labelDir       the list of all label files
% 
% Created by Haiyang Jin (09/12/2019)

if nargin < 1
    fprintf('Usage: labelDir = fs_labeldir(subjCode, labelNames);\n');
    return;
end

% label folder
labelPath = fullfile(getenv('SUBJECTS_DIR'), subjCode, 'label');

% convert string to cell
if ischar(labelNames)
    labelNames = {labelNames};
end

% number of input label
nLabelInput = numel(labelNames);

labelDir = struct([]); % empty struct 

% list files for each label input separately
for iLabelInput = 1:nLabelInput
    
    % filename and path for this file 
    thisLabel = labelNames{iLabelInput};
    
    % list all matching files
    tempDir = dir(fullfile(labelPath, thisLabel));
    
    % save information
    labelDir = [labelDir; tempDir]; %#ok<AGROW>
 
end

end