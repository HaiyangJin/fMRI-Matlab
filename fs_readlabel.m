function [dataMatrix, nVer] = fs_readlabel(labelFn, subjCode)
% read label file in FreeSurfer to matrix in Matlab
%
% Created by Haiyang Jin (28/11/2019)

if ~fs_checklabel(labelFn, subjCode)
    error('Cannot find the label "%s" for "%s"', labelFn, subjCode);
end

labelFile = fullfile(getenv('SUBJECTS_DIR'), subjCode, 'label', labelFn);

labelMatrix = importdata(labelFile, ' ', 2); % read the label file

% the data from the label file ([vertex number, x, y, z, activation])
dataMatrix = labelMatrix.data;

% vertice number in FreeSurfer starts from 0 while vertice number in Matlab
% starts from 1
dataMatrix(:, 1) = dataMatrix(:, 1) + 1;

% number of vertices
nVer = str2double(labelMatrix.textdata{2, 1});

end