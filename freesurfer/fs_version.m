function fsV = fs_version(isnum)
% fsV = fs_version(isnum)
%
% This function output the version of the FreeSurfer in use.
%
% Input:
%    isnum     <logical> whether the output should be numeric instead of
%               strings. Default is 0.
%
% Created by Haiyang Jin (23-Feb-2020)

if ~exist('isnum', 'var') || isempty(isnum)
    isnum = 0;
end

% create and run the commands
fscmd = 'recon-all -version';
[status, fsV] = system(fscmd);

if ~isnum
    % output strings
    if ~status % if FreeSurfer was setup
        % display the version
        fprintf('\nThe version of FreeSurfer in use is: \n%s \n', fsV);
    else
        warning('FreeSurfer is not set up properly.');
    end
else
    % output numeric
    tmpStr = split(fsV, '-');
    if numel(tmpStr) < 4
        fsV = 5.3;
    else
        fsV = str2double(tmpStr{4}(1:3));
    end
    
    if isnan(fsV)
        fsV = 6.0;
    end
    
end

end