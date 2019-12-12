function [dataMatrix, nVer] = fs_readlabel(label_fn, subjCode)
% read label file in FreeSurfer to matrix in Matlab
%
% Created by Haiyang Jin (28/11/2019)

FS = fs_setup;

if ~fs_checklabel(label_fn, subjCode)
    error('Cannot find the label "%s" for "%s"', label_fn, subjCode);
end

label_file = fullfile(FS.subjects, subjCode, 'label', label_fn);

labelMatrix = importdata(label_file, ' ', 2); % read the label file

% the data from the label file ([vertex number, x, y, z, activation])
dataMatrix = labelMatrix.data;

% vertice number in FreeSurfer starts from 0 while vertice number in Matlab
% starts from 1
dataMatrix(:, 1) = dataMatrix(:, 1) + 1;

% number of vertices
nVer = str2double(labelMatrix.textdata{2, 1});

end