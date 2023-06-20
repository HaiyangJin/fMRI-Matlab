function fs_samsrf_setupdir(samsrfDir)
% fs_samsrf_setupdir(samsrfDir)
%
% Set $SAMSRF_DIR.

if ~isempty(samsrfDir) && exist(samsrfDir, 'dir')
    setenv('SAMSRF_DIR', samsrfDir);
    fprintf('$SAMSRF_DIR is set as %s now...\n', samsrfDir);
end

end