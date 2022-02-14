function [fscmd, isnotok] = fs_recon(t1list, subjCode, t2list, hires, runcmd)
% [fscmd, isnotok] = fs_recon(t1File, subjCode, t2File, hires, runcmd)
%
% This function run 'recon-all' in FreeSurfer.
%
% Inputs:
%    t1list       <str> the path to the T1 file.
%              OR <cell str> a list of T1 files.
%    subjCode     <str> subject code.
%    t2list       <str> (optional) the path to the T2 file.
%              OR <cell str> a list of T2 files.
%    hires        <boo> whether run recon-all with native high resolution.
%                   default is 0.
%    runcmd       <boo> whether to run the recon-all commands [default: 1].
%
% Output:
%    fscmd        <str> FreeSurfer commands.
%    isnotok      <boo> whether the command works not properly. 0 denotes
%                  ok.
%    Projected structural data saved in $SUBJECTS_DIR.
%
% Created by Haiyang Jin (6-Feb-2020)
%
% See also:
% fs_preproc

if nargin < 1 
    fprintf('Usage: [fscmd, isnotok] = fs_recon(t1list, subjCode, t2list, hires, runcmd);\n');
    return;
end

if ~exist('runcmd', 'var') || isempty(runcmd)
    runcmd = 1;
end

% deal with T2 files
if ~exist('t2list', 'var') || isempty(t2list)
    warning('T2 will not be used during recon-all for %s.', subjCode);
    t2cmd = '';
elseif ischar(t2list)
    t2cmd = sprintf('-T2 %s ', t2list);
elseif iscell(t2list)
    t2cmd = sprintf('-T2 %s ', t2list{:});
end
if ~isempty(t2cmd)
    t2cmd = [t2cmd '-T2pial '];
end

if ~exist('hires', 'var') || isempty(hires)
    hires = 0;
end

% cmd for run with native high resolution
if hires
    hicmd = '-hires';
%     hicmd = sprintf('-hires -expert %s ', fullfile( ...
%         fm_2cmdpath(fileparts(mfilename('fullpath'))), 'expert.opts'));
else
    hicmd = '';
end

if ischar(t1list)
    t1list = {t1list};
end

fscmd = sprintf('recon-all -s %s %s %s%s  -all', ...
    subjCode, sprintf(' -i %s', t1list{:}), t2cmd, hicmd);

% display the recon-all command
fprintf('\n%s \n', fscmd);
[fscmd, isnotok] = fm_runcmd(fscmd, runcmd);

end