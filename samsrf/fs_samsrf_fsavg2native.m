function fs_samsrf_fsavg2native(prf_wc, MeshFolder, templateFolder)
% fs_samsrf_fsavg2native(prf_wc, MeshFolder, templateFolder)
%
% Use Template2NativeMap() from SamSrf to convert the labels in fsaverage
% space (in SamSrf format) to native (self surface) space. 
%
% Inputs:
%     prf_wc          <str> wildcard to list the Srf files (see more in
%                      fs_samsrf_listprfs()).
%     MeshFolder      <str> path to the 'surf' folder for this subject. If
%                      it is a relative path, it has to be relative to path
%                      to the 'Srf' folder, e.g., '../surf'. More see
%                      Template2NativeMap().
%     templateFolder  <str> the path to the template folder. More see
%                      Template2NativeMap().
%
% Some templates:
%     Benson_Atlas_fsaverage    https://osf.io/z6uwr
%     Sereno_Atlas              https://osf.io/8teuq
%
% Created by Haiyang Jin (2023-July-18)

% back up the directory
oldPath = pwd;

% list all matched Srf files
srfFnList = fs_samsrf_listprfs(prf_wc);
N_srf = length(srfFnList);

% convert for each Srf separately
for iSrf = 1:N_srf

    % change to the Srf directory
    [srfPath, fn] = fileparts(srfFnList{iSrf});
    cd(srfPath);

    % convert to native
    Template2NativeMap(fn, MeshFolder, templateFolder);
    cd(oldPath);

end

end