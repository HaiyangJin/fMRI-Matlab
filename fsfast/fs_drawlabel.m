function fscmd = fs_drawlabel(sessList, anaList, conList, varargin)
% fscmd = fs_drawlabel(sessList, anaList, conList, varargin)
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
%
% Varargin:
%    .fthresh       <num> significance level (default is 2 (.01)).
%    .extrastr      <str> extra label information added to the end of the
%                    label name. Default is ''.
%    .viewer        <int> 1 for 'tksurfer' and 2 for 'freeview'. For
%                    FS5 and FS6, default is 1 and for FS7, default is 2.
%    .addvalue      <boo> whether add the functional data/values used to
%                    create the label. Default is 1.
%    .extracmd      <str> extra commands (cmd). Default is ''.
%    .runcmd        <boo> 1: run FreeSurfer commands; 0: do not run
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

if nargin < 3
    fprintf('Usage: fscmd = fs_drawlabel(sessList, anaList, conList, varargin);\n');
    return;
end

% convert to cell if it is char
if ischar(sessList); sessList = {sessList}; end
if ischar(anaList)
    anaList = {anaList};
else
    anaList = anaList(:);
end
if ischar(conList); conList = {conList}; end

defaultOpts = struct( ...
    'fthresh', {2}, ... % p < .01
    'extrastr', {''}, ...
    'istk', fs_version(1) < 7, ... % the default viewer
    'addvalue', 1, ...
    'extracmd', '', ...
    'runcmd', 1);
opts = fm_mergestruct(defaultOpts, varargin{:});

fthresh = opts.fthresh;
if ~iscell(fthresh)
    fthresh = num2cell(fthresh);
end

if ischar(opts.extrastr)
    opts.extrastr = {opts.extrastr};
end

%% Draw labels for all participants for both hemispheres
% create all the combinations
[theExtra, theSess, theAna, theThresh, theCon] = ...
    ndgrid(opts.extrastr, sessList, anaList, fthresh, conList);

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
subjCode = fs_subjcode(sess, 1);
sigFile = fullfile(getenv('FUNCTIONALS_DIR'), sess, 'bold', ana, con, 'sig.nii.gz');
labelName = cellfun(@(x1, x2, x3, x4) sprintf('roi.%s.f%d.%s.%slabel', ...
    x1, x2*10, x3, x4), hemi, thresh, con, extraStr, 'uni', false);

% create labels
fscmdCell = cellfun(@(x1, x2, x3, x4, x5) fv_drawlabel(x1, x2, x3, x4, ...
    'fthresh', x5, 'istk', opts.istk, 'addvalue', opts.addvalue, ...
    'extracmd', opts.extracmd, 'runcmd', opts.runcmd), ...
    subjCode, ana, sigFile, labelName, thresh, 'uni', false);

% make the FreeSurfer commands to one role
fscmd = fscmdCell(:);

end