function fs_setup(fsPath)
% Set up FreeSurfer if it is not set up properly.
%
% Input:
%    fsPath         full path to FreeSurfer
%
% Created and updated by Haiyang Jin (16-Jan-2020)

if ~isempty(getenv('FREESURFER_HOME'))
    fprintf('\nFreeSurfer was already set up properly.\n\n');
    return;
end

% Default path to FreeSurfer in Mac or Linux
if nargin < 1 && isunix 
    if ismac % for Mac
        fsPath = '/Applications/freesurfer';
    elseif isunix % for linux
        fsPath = '/';  % to be set later
    else
        error('Platform not supported.');
    end
end

% please ignore this part, set fsPath as the full path to FreeSurfer
if fsPath(1) ~= filesep
    % use fsPath as the verion number if fsPath is not a full path (e.g., '5.3', '6.0') 
    fsPath = sprintf('/Applications/freesurfer_%s', fsPath);
end

% set up FreeSurfer
setenv('FREESURFER_HOME', fsPath);
iserror = system(sprintf('. %s/SetUpFreeSurfer.sh', fsPath));
fsl_setup;  % setup fsl

% throw error if FreeSurfer is not sourced successfully
assert(~iserror, sprintf('SetUpFreeSurfer.sh cannot be found at %s.', fsPath));

end
