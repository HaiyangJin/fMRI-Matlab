function fs_samsrf_initialize(subjCode, sessCode, samsrfDir)
% fs_samsrf_initialize(subjCode, sessCode, samsrfDir)
%
% Initialize the directories for SamSrf from FreeSurfer subject code
% folders in $SUBJECTS_DIR.
%
% Inputs:
%     subjCode     <str> subject code in $SUBJECTS_DIR.
%     sessCode     <str> session/folder to be created in $SAMSRF_DIR.
%     samsrfDir    <str> directory for SamSrf analysis, could be the same
%                   as $SUBJECTS_DIR. Default to $SAMSRF_DIR.
%
% Created by Haiyang Jin (2023-June-20)

if ~exist('samsrfDir', 'var') || isempty(samsrfDir)
    samsrfDir = getenv('SAMSRF_DIR');
end

% ake simlink for the sub-directories in the subject folder in $SUBJECTS_DIR
struDir = getenv('SUBJECTS_DIR');
if ~strcmp(struDir, samsrfDir)
    toLink = 1;
    force = 1;
    fs_samsrf_linksubjdir(fullfile(struDir, subjCode), ...
        fullfile(samsrfDir, sessCode), toLink, force);
end

% make new directories for SamSrf if needed
newdirs = fullfile(samsrfDir, sessCode, {'anatomy', 'apertures', 'prf'});
cellfun(@fm_mkdir, newdirs);

end