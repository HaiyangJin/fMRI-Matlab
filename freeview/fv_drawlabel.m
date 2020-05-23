function fscmd = fv_drawlabel(subjCode, anaName, sigFile, labelname, fthresh, runcmd)
% fscmd = fv_drawlabel(subjCode, anaName, sigFile, labelname, fthresh, runcmd)
%
% This function uses "tksurfer" in FreeSurfer to draw label 
% 
% Inputs:
%    subjCode         <string> subject code in $SUBJECTS_DIR.
%    anaName          <string> the analysis name.
%    fileSig          <string> usually the sig.nii.gz from localizer scans.
%    labelname        <string> the label name you want to use for this
%                      label.
%    fthresh          <string> or <numeric> the overlay threshold minimal 
%                      value.
%    runcmd           <logical> 0: do not run but only make fscmd; 1: run
%                      FreeSurfer commands. Default is 1.
%
% Output:
%    fscmd            <string> FreeSurfer commands used.
%    a label file saved in the label folder
%
% Created by Haiyang Jin (10-Dec-2019)
% For furture development, I should included to define the limits of
% p-values.

hemi = fs_2hemi(anaName);

if ~exist('fthresh', 'var') || isempty(fthresh)
    fthresh = '';
elseif isnumeric(fthresh)
    fthresh = num2str(fthresh);
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
    
    message = {sprintf('\\fontsize{20}SubjCode: %s', replace(subjCode, '_', '-'));
        sprintf('template: %s', template);
        sprintf('label: %s', labelname);
        sprintf('fthresh: %s', fthresh)};
    title = 'The current session...';
    f = msgbox(message,title, CreateStruct);
    
%     movegui(f, 'northeast');
end

% create FreeSurfer command and run it
titleStr = sprintf('%s==%s==%s', subjCode, labelname, template);
fscmd = sprintf('tksurfer %s %s inflated -aparc -overlay %s -title %s',...
    trgSubj, hemi, sigFile, titleStr);
if ~isempty(fthresh)
    fscmd = sprintf('%s -fthresh %s', fscmd, fthresh);
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

% created an empty file with the label filename
labelFile = fullfile(subjPath, subjCode, 'label', labelname);

% rename and move this label file
tempLabelFile = fullfile(subjPath, trgSubj, 'label.label');

if exist(tempLabelFile, 'file')
    movefile(tempLabelFile, labelFile);
end

% close the msgbox
close(f);

end