function fsl_setup(fslPath)
% Set up FSL if it is not set up properly.
%
% Input:
%    fslPath        the path to FSL
%
% Created by Haiyang Jin (16-Jan-2020)

% returns (stop this fucntion) if FSL is already set up properly 
if ~isempty(getenv('FSLDIR'))
    fprintf('\nFSL was already set up properly.\n\n');
    return;
end

% the default FSL path
if nargin < 1
    fslPath = '/usr/local/fsl';
end

% setup FSL
setenv('FSLDIR', fslPath);
setenv('PATH', sprintf('%s/bin:%s', getenv('FSLDIR'), getenv('PARH')));
system('export FSLDIR PATH');
iserror = system('. ${FSLDIR}/etc/fslconf/fsl.sh');

% throw error if fsl.sh is not sourced successfully
assert(~iserror, sprintf('fsl.sh cannot be found at %s/etc/fslconf/', fslPath));

end


