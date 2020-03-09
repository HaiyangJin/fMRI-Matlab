function fs_save2label(data, subjCode, labelFn, vertCoord)
% fs_save2label(dt_cosmo, subjCode, labelFn, vertCoordi)
%
% This function converts the surface dataset in CoSMoMVPA to label file in
% FreeSurfer.
% 
% Inputs:
%    data             <numeric vector> a Px1 numeric vector to be saved as
%                     a label file.
%    subjCode         <string> subject code in $SUBJECTS_DIR.
%    labelFn          <string> the filename of the label to be saved later 
%                     (without path).
%    vertCoord        <numeric array> a Px3 numeric array for the vertex 
%                     coordinates.
% 
% Output:
%    a label file saved in the label folder.
%
% Created by Haiyang Jin (25-Nov-2019)

% add the extension of '.label' if its is not
if ~endsWith(labelFn, '.label')
    labelFn = [labelFn '.label'];
end

% label folder for this subject
labelFile = fullfile(getenv('SUBJECTS_DIR'), subjCode, 'label', labelFn);

% classification accuracies for each vertex
nVtx = numel(data);

% open a file for saving the label information
fid = fopen(labelFile, 'w');

% saving information in the label file
fprintf(fid, '#!ascii label. subject-%s coords=surface\n', subjCode);
fprintf(fid, '%d\n', nVtx);
for vtxID = 1:nVtx
    fprintf(fid, '%d %5.3f %5.3f %5.3f %f\n', vtxID-1, vertCoord(vtxID, 1), ...
        vertCoord(vtxID, 2), vertCoord(vtxID, 3), data(vtxID));  
end
fclose(fid);

fprintf('Saved %s label for %s.\n', [fn ext], subjCode);

end