function samsrfDir = fs_samsrfdir(samsrfDir)
% fs_samsrfdir(samsrfDir)
%
% Set $SAMSRF_DIR.

if ~exist('samsrfDir', 'var') 
    samsrfDir = getenv('SAMSRF_DIR');
elseif ~isempty(samsrfDir) && exist(samsrfDir, 'dir')
    setenv('SAMSRF_DIR', samsrfDir);
    fprintf('$SAMSRF_DIR is set as %s now...\n', samsrfDir);
else
    warning('SAMSRF_DIR is not set up.')
end

end