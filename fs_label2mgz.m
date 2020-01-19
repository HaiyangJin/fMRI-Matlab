function fs_label2mgz(subjCode, labelFn, filetype)
% This function converts a label file (with all vertices) into a mgz file.
% [This is probably not that useful except in some extreme cases].
%
% Inputs:
%    subjCode           subject code in "SUBJECTS_DIR" in FreeSurfer
%    labelFn            filename of the label (without path)
%    filetype           *.mgz or *.mgh (uncompressed)
% Output:
%    a mgz file saved in SUBJECTS_DIR/subjCode/surf/
%
% Created by Haiyang Jin (19-Jan-2020)

if nargin < 3
    filetype = 'mgz';
end

% load label file
dataMat = fs_readlabel(subjCode, labelFn);

% get the surface data
surfData = dataMat(:, 5);  % the fifth column will be the surface data

% filename of the mgz file
mgzFn = strrep(labelFn, 'label', filetype);

% save the mgz file
fs_savemgz(subjCode, surfData, mgzFn);

end