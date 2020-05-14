function labelFile = fs_save2label(data, subjCode, labelFn, coordSurf)
% fs_save2label(data, subjCode, labelFn)
%
% This function converts the surface dataset in CoSMoMVPA to label file in
% FreeSurfer.
% 
% Inputs:
%    data             <numeric vector> a Px5 numeric vector to be saved as
%                      a label file. The first column is the verte indices.
%                      The second to forth columns are their XYZ coordinates
%                      on ?h.white surface. The fifth column is the values
%                      for each vertex.
%    subjCode         <string> subject code in $SUBJECTS_DIR.
%    labelFn          <string> the filename of the label to be saved later 
%                      (without path).
%    coordSurf        <string> coordinates on which surface. Default is
%                      'white'.
% 
% Output:
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
nVtx = size(data, 1);

% open a file for saving the label information
fid = fopen(labelFile, 'w');

% saving information in the label file
fprintf(fid, '#!ascii label  from subject %s coords=%s\n', subjCode, coordSurf);
fprintf(fid, '%d\n', nVtx);
for vtxID = 1:nVtx
    fprintf(fid, '%d %5.3f %5.3f %5.3f %f\n', data(vtxID, 1)-1, data(vtxID, 2), ...
        data(vtxID, 3), data(vtxID, 4), data(vtxID, 5));  
end
fclose(fid);

fprintf('Saved %s label for %s.\n', labelFn, subjCode);

end