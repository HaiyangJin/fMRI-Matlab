function fs_cosmo_map2label(dt, filename, vert_coordi, subjCode)
% This function convert the surface dataset in CoSMoMVPA to label file in
% FreeSurfer.
%
% Created by Haiyang Jin (25/11/2019)

% dt only refers to the dt obtained from searchlight analyses for surface.

[~, fn, ext] = fileparts(filename);
if ~strcmp(ext, '.label')
    filename = [filename '.label'];
end

acc = dt.samples;
nver = numel(acc);

fid = fopen(filename, 'w');
fprintf(fid, '#!ascii label Converted from CosmoMVPA. subject-%s coords=surface\n', subjCode);
fprintf(fid, '%d\n', nver);
for vID = 1:nver
    fprintf(fid, '%d %5.3f %5.3f %5.3f %f\n', vID-1, vert_coordi(vID, 1), ...
        vert_coordi(vID, 2), vert_coordi(vID, 3), acc(vID));  
end
fclose(fid);
fprintf('Saved %s label for %s.\n', fn, subjCode);
end