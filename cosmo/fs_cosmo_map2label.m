function fs_cosmo_map2label(dt_cosmo, subjCode, labelFn, vertCoordi)
% This function convert the surface dataset in CoSMoMVPA to label file in
% FreeSurfer.
% 
% Inputs:
%    dt_cosmo         results of searchlight in datasets (only refers to the
%                     dt obtained from searchlight analyses for surface)
%    subjCode         subject code in $SUBJECTS_DIR
%    labelFn         the filename of the label to be saved later (without
%                     path)
%    vertCoordi      vertex coordinates
% Output:
%    a label file saved in the label folder
%
% Created by Haiyang Jin (25/11/2019)
% Updated by Haiyang Jin (15/12/2019)

% add the extension of '.label' if its is not
[~, fn, ext] = fileparts(labelFn);
if ~strcmp(ext, '.label')
    labelFn = [labelFn '.label'];
end

% label folder for this subject
labelFile = fullfile(getenv('SUBJECTS_DIR'), subjCode, 'label', labelFn);

% classification accuracies for each vertex
acc = dt_cosmo.samples;
nVtx = numel(acc);

% open a file for saving the label information
fid = fopen(labelFile, 'w');

% saving information in the label file
fprintf(fid, '#!ascii label Converted from CosmoMVPA. subject-%s coords=surface\n', subjCode);
fprintf(fid, '%d\n', nVtx);
for vtxID = 1:nVtx
    fprintf(fid, '%d %5.3f %5.3f %5.3f %f\n', vtxID-1, vertCoordi(vtxID, 1), ...
        vertCoordi(vtxID, 2), vertCoordi(vtxID, 3), acc(vtxID));  
end
fclose(fid);

fprintf('Saved %s label for %s.\n', [fn ext], subjCode);

end