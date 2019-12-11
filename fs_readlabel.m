function [dataMatrix, nVer] = fs_readlabel(file_label)
% read label file in FreeSurfer to matrix in Matlab
%
% Created by Haiyang Jin (28/11/2019)

% throw error if cannot find the label
if ~exist(file_label, 'file')
    [path, fn, ext] = fileparts(file_label);
    error('Cannot find the label "%s" at "%s"', [fn ext], path);
end

labelMatrix = importdata(file_label, ' ', 2); % read the label file

% the data from the label file ([vertex number, x, y, z, activation])
dataMatrix = labelMatrix.data;

% vertice number in FreeSurfer starts from 0 while vertice number in Matlab
% starts from 1
dataMatrix(:, 1) = dataMatrix(:, 1) + 1;

% number of vertices
nVer = str2double(labelMatrix.textdata{2, 1});

end