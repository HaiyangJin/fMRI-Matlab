function fscmd = fv_drawlabel(subjCode, anaName, sigFile, labelname, ...
    fthresh, istk, extracmd, runcmd)
% fscmd = fv_drawlabel(subjCode, anaName, sigFile, labelname, ...
%    fthresh, istk, extracmd, runcmd)
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
%    fthresh          <str> or <nume> the overlay threshold minimal value.
%    istk             <int> 1 for 'tksurfer' [note: not tksurfer-sess] and 
%                      0 for fv_surf(), which implements custom codes to
%                      run freeview. For FS5 and FS6, default is 1. For
%                      FS7, default is 0.
%    extracmd         <str> extra commands for the viewer. Default is ''.
%    runcmd           <boo> 0: do not run but only make fscmd; 1: run
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
% For furture development, I should included to define the limits of
% p-values.
%
% See also:
% fs_drawlabel

if nargin < 1
    fprintf('Usage: fscmd = fv_drawlabel(subjCode, anaName, sigFile, labelname, varargin);\n');
    return;
end

hemi = fm_2hemi(anaName);

if ~exist('fthresh', 'var') || isempty(fthresh)
    fthresh = '';
elseif isnumeric(fthresh)
    fthresh = num2str(fthresh);
end
% the default viewer
if ~exist('istk', 'var') || isempty(istk)
   istk = fs_version(1) < 7;
end
    
if ~exist('extracmd', 'var') || isempty(extracmd)
    extracmd = '';
end
if ~exist('runcmd', 'var') || isempty(runcmd)
    runcmd = 1;
end

subjPath = getenv('SUBJECTS_DIR');

% find the template for this analysis
template = fs_2template(anaName, '', 'self');
trgSubj = fs_trgsubj(subjCode, template);

if runcmd
    
    % open a message box to display information
    CreateStruct.Interpreter = 'tex';
    CreateStruct.WindowStyle = 'modal';
    % msgbox('\fontsize{18} Now is big =)', CreateStruct)
    
    message = {sprintf('\\fontsize{20}SubjCode: %s', replace(subjCode, '_', '\_'));
        sprintf('analysis: %s', replace(anaName, '_', '\_'));
        sprintf('label: %s', labelname);
        sprintf('fthresh: %s', fthresh)};
    title = 'The current session...';
    f = msgbox(message,title, CreateStruct);
    
%     movegui(f, 'northeast');
end

% create FreeSurfer command and run it
titleStr = sprintf('%s==%s==%s', subjCode, labelname, anaName);

if istk
    % use tksurfer (cannot be tested now)
    fscmd = sprintf('tksurfer %s %s inflated -aparc -overlay %s -title %s %s',...
        trgSubj, hemi, sigFile, titleStr, extracmd);
    if ~isempty(fthresh)
        fscmd = sprintf('%s -fthresh %s', fscmd, fthresh);
    end
    tmpLabelname = 'label.label';
else
    % use freeview
    opts.surftype = 'inflated';
    opts.threshold = [fthresh ',5'];
    opts.annot = 'aparc';
    opts.overlay = sigFile;
    opts.runcmd = 0;
    % get the surface codes
    tmpMgz = fullfile(getenv('SUBJECTS_DIR'), subjCode, 'surf', ...
        sprintf('%s.w-g.pct.mgh', hemi));
    [~, fscmd] = fv_surf(tmpMgz, trgSubj, opts);
    tmpLabelname = fullfile('label', 'label_1.label');
end

% finish this command if do not need to run fscmd
if ~runcmd; return; end
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
labelFile = fullfile(subjPath, subjCode, 'label', labelname);

% rename and move this label file
tempLabelFile = fullfile(subjPath, trgSubj, tmpLabelname);

if logical(exist(tempLabelFile, 'file'))
    movefile(tempLabelFile, labelFile);
    fprintf('Label %s is saved.\n', labelname);
end

%% Add sig values if freeview is used
% if ~istk
%     fs_labelval(labelname, subjCode, sigFile);
% end

% close the msgbox
close(f);

end