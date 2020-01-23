function fs_setupmatlab
% function fs_setupmatlab
%
% This function adds the path to the current version of Matlab to $PATH.
%
% Created by Haiyang Jin (23-Jan-2020)

% get the PATH in the global environment
thePath = getenv('PATH');

% get the Matlab root folder
matlabPath = sprintf('%s/bin', matlabroot);

% check if the current Matlab is already in the PATH
strStart = regexpi(thePath, matlabPath);

if logical(strStart)
    % print the version of Matlab will be used
    fprintf('\n%s was already in the $PATH.\n\n', matlabPath);
else
    % add the current Matlab to the PATH
    setenv('PATH', sprintf('%s:%s', matlabPath, getenv('PATH')));
    
    fprintf('\n%s is added to the $PATH.\n\n', matlabPath);
end

end