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
%    .coordsurf     <str> the surface name for showing coordinates, default
%                    to 'white'.
%    .distmetric    <str> method to be used to calculate the distance. 
%                    Default to 'geodesic' (or 'dijkstra').
%    .addvalue      <boo> whether add the functional data/values used to
%                    create the label. Default to true.
%    .extracmd      <str> extra commands (cmd). Default to ''.
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
% Created by Haiyang Jin (2019-Dec-10)

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
    'coordsurf', 'white', ...
    'distmetric', 'geodesic', ...
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
%%% clean the extra strings %%%
% add variable name
hasname = cellfun(@(x) contains(x, '-'), opts.extrastr);
opts.extrastr(~hasname) = cellfun(@(x) sprintf('_custom-%s', x), ...
    opts.extrastr(~hasname), 'uni', false);
% remove '_' at the end
endunderscore = cellfun(@(x) endsWith(x, '_'), opts.extrastr);
opts.extrastr(endunderscore) = cellfun(@(x) x(1:end-1), ...
    opts.extrastr(endunderscore), 'uni', false);
% ensure starts with '_'
startunderscore = cellfun(@(x) startsWith(x, '_'), opts.extrastr);
opts.extrastr(~startunderscore) = cellfun(@(x) ['_' x], ...
    opts.extrastr(~startunderscore), 'uni', false);

%% Draw labels for all participants for both hemispheres
% create all the combinations
[theExtra, theSess, theAna, theThresh, theCon] = ...
    ndgrid(opts.extrastr, sessList, anaList, fthresh, conList);

ana = theAna(:);
sess = theSess(:);
con = theCon(:);
thresh = theThresh(:);
extraStr = theExtra(:);

% obtain necessary information
hemi = cellfun(@fm_2hemi, ana, 'uni', false);
subjCode = fs_subjcode(sess, 1);
sigFile = fullfile(getenv('FUNCTIONALS_DIR'), sess, 'bold', ana, con, 'sig.nii.gz');
labelName = cellfun(@(x1, x2, x3, x4) sprintf('cont-%s_hemi-%s%s_type-f%d_froi.label', ...
    x1, x2, x3, x4*10), strrep(con, '-', '='), hemi, extraStr, thresh, 'uni', false);

% create labels
fscmdCell = cellfun(@(x1, x2, x3, x4, x5) fv_drawlabel(x1, x2, x3, x4, ...
    'fthresh', x5, 'istk', opts.istk, 'coordsurf', opts.coordsurf, ...
    'addvalue', opts.addvalue, 'extracmd', opts.extracmd, ...
    'runcmd', opts.runcmd), ...
    subjCode, ana, sigFile, labelName, thresh, 'uni', false);

% make the FreeSurfer commands to one role
fscmd = fscmdCell(:);

end