function fscmd = fv_drawlabel(subjCode, anaName, sigFile, labelname, varargin)
% fscmd = fv_drawlabel(subjCode, anaName, sigFile, labelname, varargin)
%
% This function uses "tksurfer" in FreeSurfer to draw label. You may want
% to use fs_drawlabel().
% 
% Inputs:
%    subjCode         <str> subject code in $SUBJECTS_DIR.
%    anaName          <str> the analysis name.
%    sigFile          <str> usually the sig.nii.gz from localizer scans.
%                      This should include the path to the file if needed.
%    labelname        <str> the label name you want to use for this
%                      label.
%
% Varargin:
%    .fthresh         <str> or <num> the overlay threshold minimal value.
%    .istk            <int> 1 for 'tksurfer' [note: not tksurfer-sess] and 
%                      0 for fv_surf(), which implements custom codes to
%                      run freeview. For FS5 and FS6, default is 1. For
%                      FS7, default is 0.
%    .addvalue        <boo> whether add the functional data/values used to
%                      create the label when 'freeview' is used. Default is
%                      1.
%    .extracmd        <str> extra commands for the viewer. Default is ''.
%    .runcmd          <boo> 0: do not run but only make fscmd; 1: run
%                      FreeSurfer commands. Default is 1.
%
% Output:
%    fscmd            <string> FreeSurfer commands used.
%    a label file saved in the label folder
%
% Tips:
% To invert the display of overlay, set extracmd as '-invphaseflag 1'.
% 
% Created by Haiyang Jin (10-Dec-2019)
% Furture development should include defining the limits of p-values.
%
% See also:
% fs_drawlabel

if nargin < 1
    fprintf('Usage: fscmd = fv_drawlabel(subjCode, anaName, sigFile, labelname, varargin);\n');
    return;
end

hemi = fm_2hemi(anaName);

defaultOpts = struct( ...
    'fthresh', '', ...
    'istk', fs_version(1) < 7, ... % the default viewer
    'addvalue', 1, ...
    'extracmd', '', ...
    'runcmd', 1);
opts = fm_mergestruct(defaultOpts, varargin{:});

fthresh = opts.fthresh;
if isnumeric(fthresh)
    fthresh = num2str(fthresh);
end

% find the template for this analysis
template = fs_2template(anaName, '', 'self');
trgSubj = fs_trgsubj(subjCode, template);

% print the information
fprintf('\nSubjCode: %s\nAnalysis: %s\nLabel: %s\nfthresh: %s\n\n', ...
    subjCode, anaName, labelname, fthresh);

% create FreeSurfer command and run it
titleStr = sprintf('%s==%s==%s', subjCode, labelname, anaName);

if opts.istk
    % use tksurfer (cannot be tested now)
    fscmd = sprintf('tksurfer %s %s inflated -aparc -overlay %s -title %s %s',...
        trgSubj, hemi, sigFile, titleStr, opts.extracmd);
    if ~isempty(fthresh)
        fscmd = sprintf('%s -fthresh %s', fscmd, fthresh);
    end
    tmpLabelname = 'label.label';
else
    % use freeview
    fvopts.surftype = 'inflated';
    fvopts.threshold = [fthresh ',5'];
    fvopts.annot = 'aparc';
    fvopts.overlay = sigFile;
    fvopts.runcmd = 0;
    % get the surface codes
    tmpMgz = fullfile(getenv('SUBJECTS_DIR'), subjCode, 'surf', ...
        sprintf('%s.w-g.pct.mgh', hemi));
    [~, fscmd] = fv_surf(tmpMgz, trgSubj, fvopts);
    tmpLabelname = fullfile('label', 'label_1.label');
end

% finish this command if do not need to run fscmd
if ~opts.runcmd; return; end
system(fscmd);

%%%%%%%%%%%%%%%% Manual working in FreeSurfer %%%%%%%%%%%%%%%%%%%%%%%%%%%%
% IMPORTANT: Please make sure you started X11
% 1. click any vertex in the region;
% 2. fill it with "similar" vertices;
%    1.Custom Fill;
%    2.make sure "Up to and including paths" and "up to funcitonal values
%      below threhold" are selected;
%    3.click "Fill".
% 3. Save that area as a label file;
% NOTE: please name the label as label.label in the folder
% ($SUBJECTS_DIR/subjCode/label.label) Basically, you only need to delect
% the "/" in the default folder or filename
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Rename the label file
% created an empty file with the label filename
labelFile = fullfile(getenv('SUBJECTS_DIR'), subjCode, 'label', labelname);

% rename and move this label file
tmpLabelFile = fullfile(getenv('SUBJECTS_DIR'), trgSubj, tmpLabelname);

if logical(exist(tmpLabelFile, 'file'))

    tooverwrite = 'move';
    % throw warning if the target label exists
    if logical(exist(labelFile, 'file'))
        fig1 = uifigure;
        tooverwrite = uiconfirm(fig1, 'Overwrite the target label file?', ...
            'The target label file already exists...', 'Icon', 'warning');
        close(fig1);
    end

    switch tooverwrite
        case 'move'
            movefile(tmpLabelFile, labelFile);
            fprintf('Label %s is created.\n', labelname);
        case 'OK'
            movefile(tmpLabelFile, labelFile);
            fprintf('Label %s is overwritten.\n', labelname);
        case 'Cancel'
            delete(tmpLabelFile)
            fprintf('The old %s is not updated.\n', labelname);
    end
end

% Add sig values if freeview is used
if ~opts.istk && opts.addvalue
    fs_labelval(labelname, subjCode, sigFile);
end

end