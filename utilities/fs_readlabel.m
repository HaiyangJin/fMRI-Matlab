function [dataMatrix, nVtx] = fs_readlabel(subjCode, labelFn)
% [dataMatrix, nVtx] = fs_readlabel(subjCode, labelFn)
%
% load label file in FreeSurfer to matrix in Matlab
%
% Inputs:
%     subjCode        <string> subject code in SUBJECTS_DIR or full path  
%                      to this subject code folder. [Tip: if you want to
%                      inspect the subject in the current working
%                      directory, run fv_checkrecon('./labelFn').
%     labelFn         <string> filename of the label file (without
%                      path).
%
% Outputs:
%     dataMatrix      <numeric array> the data matrix from the label file.
%     nVtx            <numeric> number of vertices.
%
% Created by Haiyang Jin (28-Nov-2019)

% check if the path is available
filepath = fileparts(subjCode);

if isempty(filepath)
    % use SUBJECTS_DIR as the default subject path
    labelFile = fullfile(getenv('SUBJECTS_DIR'), subjCode, 'label', labelFn);
    
else
    % use the label filename directly
    labelFile = subjCode;
end

% make sure the label file is available
assert(logical(exist(labelFile, 'file')), 'Cannot find the label file: %s.', labelFile);

% read the label file
labelMatrix = importdata(labelFile, ' ', 2);

% the data from the label file ([vertex number, x, y, z, activation])
dataMatrix = labelMatrix.data;

% vertice number in FreeSurfer starts from 0 while vertice number in Matlab
% starts from 1
dataMatrix(:, 1) = dataMatrix(:, 1) + 1;

% number of vertices
nVtx = str2double(labelMatrix.textdata{2, 1});

end