function fsl_setup(fslPath)
% fsl_setup(fslPath);
% Set up FSL if it is not set up properly.
%
% Input:
%    fslPath        the path to the folder where FSL is installed
%
% Created by Haiyang Jin (16-Jan-2020)

% returns (stop this fucntion) if FSL is already set up properly 
if ~isempty(getenv('FSLDIR'))
    fprintf('\nFSL was already set up properly.\n\n');
    return;
end

% the default FSL path
if nargin < 1 || isempty(fslPath)
    fslPath = '/usr/local/fsl';
end

% setup FSL
setenv('FSLDIR', fslPath);
setenv('PATH', sprintf('%s/bin:%s', getenv('FSLDIR'), getenv('PATH')));
setenv('FSLOUTPUTTYPE', 'NIFTI_GZ'); 
system('export FSLDIR PATH');
iserror = system('sh ${FSLDIR}/etc/fslconf/fsl.sh');

% throw error if fsl.sh is not sourced successfully
assert(~iserror, sprintf('fsl.sh cannot be found at %s/etc/fslconf/', fslPath));

fprintf('\nFSL is set up successfully [I hope so].\n\n');

end


