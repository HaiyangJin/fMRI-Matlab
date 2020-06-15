function gm = fs_labelgm(labelFn, subjCode)
% gm = fs_labelgm(labelFn, subjCode)
%
% This function reads the global maxima file for the label file. They
% should be stored in the same directory (i.e., in the label/ folder) and
% share the same filename (but different extensions; '.label' for the label
% and '.gm' for the globalmaxima file).
%
% Inputs:
%    labelFn         <string> filename of the label file (with or without
%                     path). If path is included in labelFn, 'subjCode'
%                     and struPath will be ignored. Default is
%                     'no.label', i.e., no labels.
%    subjCode        <string> subject code in struPath. Default is
%                     fsaverage.
%
% Output:
%    gm              <integer> the vertex index for the global maxima.
%
% Created by Haiyang Jin (15-Jun-2020)

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