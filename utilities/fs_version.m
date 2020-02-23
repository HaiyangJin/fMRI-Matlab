function fsV = fs_version
% fsV = fs_version
%
% This function output the version of the FreeSurfer in use.
%
% Created by Haiyang Jin (23-Feb-2020)

% create and run the commands
fscmd = 'recon-all -version';
[status, fsV] = system(fscmd);

if ~status % if FreeSurfer was setup
    % display the version
    fprintf('\nThe version of the FreeSurfer in use is: \n%s \n', fsV);
else
    warning('FreeSurfer is not set up properly.');
end

end