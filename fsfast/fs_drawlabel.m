function fscmd = fs_drawlabel(sessList, anaList, conList, fthresh, ...
    extraLabelStr, viewer, extracmd, runcmd)
% fscmd = fs_drawlabel(sessList, anaList, conList, fthresh, ...
%    extraLabelStr, viewer, extracmd, runcmd)
%
% This function use FreeSurfer ("tksurfer") to draw labels.
%
% Inputs:
%    sessList       <str> session code in $FUNCTIONALS_DIR;
%                   <cell str> cell of session codes in
%                    %SUBJECTS_DIR.
%    anaList        <str> or <cell str> the names of the analysis (i.e.,
%                    the names of the analysis folders).
%    conList        <str> contrast name used glm (i.e., the names of
%                    contrast folders).
%    fthresh        <num> significance level (default is 2 (.01)).
%    extraLabelStr  <str> extra label information added to the end
%                    of the label name.
%    viewer         <int> 1 for 'tksurfer' and 2 for 'freeview'. For
%                    FS5 and FS6, default is 1 and for FS7, default is 2.
%    extracmd       <str> extra commands for 'tksurfer'. Default is ''.
%    runcmd         <boo> 1: run FreeSurfer commands; 0: do not run
%                    but only output FreeSurfer commands. 
%
% Tips:
% To invert the display of overlay, set extracmd as '-invphaseflag 1'.
%
% To manually input commands in terminal (for FreeSurfer)
% In FreeSurfer 5.3:
%   tksurfer-sess -s subjfunc -a analysis.lh -c f-vs-o -fthresh 2
% In FreeSurfer 6.0:
%   tksurfer-sess -s subjfunc -a analysis.lh -c f-vs-o -fthresh 2 -tksurfer
%
% Output:
%    fscmd          <string> FreeSurfer commands used.
%    a label saved in the label/ folder within $SUBJECTS_DIR
%
% Created by Haiyang Jin (10-Dec-2019)

% convert to cell if it is char
if ischar(sessList); sessList = {sessList}; end
if ischar(anaList); anaList = {anaList}; end
if ischar(conList); conList = {conList}; end

if ~exist('fthresh', 'var') || isempty(fthresh)
    fthresh = {2}; % p < .01
elseif ~iscell(fthresh)
    fthresh = num2cell(fthresh);
end
if ~exist('extraLabelStr', 'var') || isempty(extraLabelStr)
    extraLabelStr = {''};
elseif ischar(extraLabelStr)
    extraLabelStr = {extraLabelStr};
end
if ~exist('viewer', 'var') || isempty(viewer)
    viewer = '';
end
if ~exist('extracmd', 'var') || isempty(extracmd)
    extracmd = '';
end
if ~exist('runcmd', 'var') || isempty(runcmd)
    runcmd = 1;
end


%% Draw labels for all participants for both hemispheres
% create all the combinations
[theExtra, theSess, theAna, theThresh, theCon] = ...
    ndgrid(extraLabelStr, sessList, anaList, fthresh, conList);

ana = theAna(:);
sess = theSess(:);
con = theCon(:);
thresh = theThresh(:);
extraStr = theExtra(:);

% add '.' at the end if necessary
notdot = cellfun(@(x) ~endsWith(x, '.') & ~isempty(x), extraStr);
extraStr(notdot) = cellfun(@(x) [x '.'], extraStr(notdot), 'uni', false);

% obtain necessary information
hemi = cellfun(@fm_2hemi, ana, 'uni', false);
subjCode = fs_subjcode(x, sess);
sigFile = fullfile(getenv('FUNCTIONALS_DIR'), sess, 'bold', ana, con, 'sig.nii.gz');
labelName = cellfun(@(x1, x2, x3, x4) sprintf('roi.%s.f%d.%s.%slabel', ...
    x1, x2*10, x3, x4), hemi, thresh, con, extraStr, 'uni', false);

% create labels
fscmdCell = cellfun(@(x1, x2, x3, x4, x5) fv_drawlabel(x1, x2, x3, x4, x5, ...
    viewer, extracmd, runcmd), ...
    subjCode, ana, sigFile, labelName, thresh, 'uni', false);

% make the FreeSurfer commands to one role
fscmd = fscmdCell(:);

end