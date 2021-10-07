function fs_setup(fsPath, fslPath, force)
% fs_setup(fsPath, fslPath, force)
%
% Set up FreeSurfer if it is not set up properly.
%
% Input:
%    fsPath       <string> path to the folder where FreeSurfer is installed
%                  and it will be set as $FREESURFER_HOME. Use fs_setup(pwd) 
%                  for setting the current folder as fsPath.
%    fslPath      <string> full path to the folder where FSL is 
%                  installed and it will be set as $FSLDIR.
%    force        <logical> force setting fsPath as $FREESURFER_HOME. 
%                  Default is 0.
%
% Created by Haiyang Jin (16-Jan-2020)

% setup matlab
fs_setupmatlab;

if ~exist('fslPath', 'var') || isempty(fslPath)
    fslPath = '';
end
if ~exist('force', 'var') || isempty(force)
    force = 0;
end

if ~isempty(getenv('FREESURFER_HOME'))&& ~force
    fprintf('\nFreeSurfer was already set up (but it may not be set up properly if you see warning below).\n\n');
    fs_version; % display the version of FreeSurfer
    return;
end

% Default path to FreeSurfer in Mac or Linux
if nargin < 1 || isempty(fsPath) && isunix 
    if ismac % for Mac
        fsPath = '/Applications/freesurfer';
    elseif isunix % for linux
        fsPath = '/usr/local/freesurfer';
    else
        error('Platform not supported.');
    end
end

% please ignore this part and just set fsPath as the full path to FreeSurfer
if ~ismember(filesep, fsPath)
    % use fsPath as the verion number if fsPath is not a path 
    % (e.g., '5.3', '6.0', '7.2') 
    fsPath = sprintf('/Applications/freesurfer_%s', fsPath);
end

%% Set up FreeSurfer
setenv('FREESURFER_HOME', fsPath);
setenv('SUBJECTS_DIR', fullfile(fsPath, 'subjects'));

iserror = system(sprintf('source %s/FreeSurferEnv.sh', fsPath));

% throw error if FreeSurfer is not sourced successfully
if iserror
    setenv('FREESURFER_HOME', '');
    error('SetUpFreeSurfer.sh cannot be found at %s.', fsPath);
end

fsl_setup(fslPath);  % setup fsl

%% Set PATH and environemnt variable
% setenv('PATH', sprintf('/usr/bin:%s', getenv('PATH'))); % add /usr/bin to PATH
setenv('PATH', sprintf('/usr/local/bin:%s', getenv('PATH'))); % add /usr/local/bin to PATH
setenv('PATH', sprintf('%s/tktools:%s', fsPath, getenv('PATH'))); % add /Applications/freesurfer/tktools: to PATH
setenv('PATH', sprintf('%s/fsfast/bin:%s', fsPath, getenv('PATH'))); % add /Applications/freesurfer/fsfast/bin: to PATH
setenv('PATH', sprintf('%s/bin:%s', fsPath, getenv('PATH'))); % add /Applications/freesurfer/bin: to PATH

setenv('FSFAST_HOME', fullfile(fsPath, 'fsfast'));
setenv('FSF_OUTPUT_FORMAT', 'nii.gz');
setenv('MNI_DIR', fullfile(fsPath, 'mni'));

% copy from startup.m for Matlab
%------------ FreeSurfer -----------------------------%
fshome = getenv('FREESURFER_HOME');
fsmatlab = sprintf('%s/matlab',fshome);
if (exist(fsmatlab) == 7)
    addpath(genpath(fsmatlab));
end
clear fshome fsmatlab;
%-----------------------------------------------------%

%------------ FreeSurfer FAST ------------------------%
fsfasthome = getenv('FSFAST_HOME');
fsfasttoolbox = sprintf('%s/toolbox',fsfasthome);
if (exist(fsfasttoolbox) == 7)
    path(path,fsfasttoolbox);
end
clear fsfasthome fsfasttoolbox;
%-----------------------------------------------------%

fprintf('\nFreeSurfer is set up successfully [I hope so].\n\n');

%% Display the version of the FreeSurfer in use
fs_version;

end
