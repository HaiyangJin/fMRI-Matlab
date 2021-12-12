function labelFile = fs_mklabel(data, subjCode, labelFn, coordSurf)
% labelFile = fs_mklabel(data, subjCode, labelFn, coordSurf)
%
% This function converts the surface dataset in CoSMoMVPA to label file in
% FreeSurfer. It also can save ones in a binary mask as a label. [Note: the
% vertex index in the first column starts from 1.]
% 
% Inputs:
%    data             <num vector> a Px5 numeric vector to be saved as
%                      a label file. The first column is the vertex indices.
%                      The second to forth columns are their XYZ coordinates
%                      on ?h.white surface. The fifth column is the values
%                      for each vertex. [The first column (vertex index)
%                      starts from 0.]
%                   OR If 'data' is a bianry mask, the 1 will be saved in
%                      the label.
%    subjCode         <str> subject code in $SUBJECTS_DIR.
%    labelFn          <str> the filename of the label to be saved later 
%                      (without path).
%    coordSurf        <str> coordinates on which surface. Default is
%                      'white'.
% 
% Output:
%    labelFile        <str> full filename of the label file.
%    a label file saved in the label folder.
%
% Created by Haiyang Jin (25-Nov-2019)

if ~exist('coordSurf', 'var') || isempty(coordSurf)
    coordSurf = 'white';
end

% add the extension of '.label' if its is not
if ~endsWith(labelFn, '.label')
    labelFn = [labelFn '.label'];
end

% label folder for this subject
labelFile = fullfile(getenv('SUBJECTS_DIR'), subjCode, 'label', labelFn);

% classification accuracies for each vertex
nCol = size(data, 2);
if nCol == 1 && all(ismember(unique(data), [0, 1]))
    hemi = fm_2hemi(labelFn);
    mask = logical(data);
    % add the coordinates on coordSurf
    coords = fs_readsurf([hemi '.' coordSurf], subjCode);
    
    data = find(mask); % index in FreeSurfer
    data(:, 2:4) = coords(mask, :);
    data(:, 5) = zeros(size(data,1),1);
    
elseif nCol ~= 5
    error('Cannot deal with ''data''. It has to be 5-column matrix or 1-column binary mask.');
end
nVtx = size(data, 1);

% open a file for saving the label information
fid = fopen(labelFile, 'w');

% saving information in the label file
fprintf(fid, '#!ascii label  from subject %s coords=%s\n', subjCode, coordSurf);
fprintf(fid, '%d\n', nVtx);
for vtxID = 1:nVtx
    % convert index starting from 1 to starting from 0
    fprintf(fid, '%d %5.3f %5.3f %5.3f %f\n', data(vtxID, 1)-1, data(vtxID, 2), ...
        data(vtxID, 3), data(vtxID, 4), data(vtxID, 5));  
end
fclose(fid);

fprintf('Saved %s label for %s.\n', labelFn, subjCode);

end