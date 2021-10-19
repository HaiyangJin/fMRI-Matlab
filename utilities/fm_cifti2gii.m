function gfiles = fm_cifti2gii(cfile)
% gfiles = fm_cifti2gii(cfile)
%
% This function saves the cortex data in cfile as two gifti files (in the
% same folder).
%
% Input:
%    cfile       <str> the cifti file to be load.
%
% Output:
%    gfiles      <cell str> a list of output gii files.
%
% Created by Haiyang Jin (2021-10-18)

if ~endsWith(cfile, '.nii')
    error('Please make sure the input file is cifti.');
end
assert(logical(exist(cfile, 'file')), 'Cannot find the cifti file:\n%s', cfile);

% read the file
[cdata, info] = fm_readimg(cfile);
[thispath, fn] = fileparts(cfile);

gfiles = cell(2,1);

% save data for the two hemisphere separately
for iLR = 1:2

    hemiInfo = info.diminfo{1,1}.models{iLR};

    % save the data for this hemisphere
    hemidata = zeros(hemiInfo.numvert,1);
    hemidata(hemiInfo.vertlist+1) = cdata(hemiInfo.start+(0:hemiInfo.count-1), :);

    % save the data as a gifti object
    sdata = struct;
    sdata.cdata = hemidata;
    gdata = gifti(sdata);
    % add the second column to cdata; otherwise it cannot be read by
    % Freeviewe for unknown reason
    gdata.cdata = [hemidata, zeros(hemiInfo.numvert,1)];

    % save the gifti file
    tmpfn = fullfile(thispath, sprintf('%s.%s.gii', fn, hemiInfo.struct(8)));
    save(gdata, tmpfn);

    gfiles{iLR} = tmpfn;
end

end