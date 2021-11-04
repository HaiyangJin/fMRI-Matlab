function [fscmd, isok] = fs_recon(t1list, subjCode, t2list, runcmd)
% [fscmd, isok] = fs_recon(t1File, subjCode, t2File, runcmd)
%
% This function run 'recon-all' in FreeSurfer.
%
% Inputs:
%    t1list       <str> the path to the T1 file.
%              OR <cell str> a list of T1 files.
%    subjCode     <str> subject code.
%    t2list       <str> (optional) the path to the T2 file.
%              OR <cell str> a list of T2 files.
%    runcmd       <boo> whether to run the recon-all commands [default: 1].
%
% Output:
%    fscmd        <str> FreeSurfer commands.
%    isok         <boo> whether the command works properly.
%    Projected structural data saved in $SUBJECTS_DIR.
%
% Created by Haiyang Jin (6-Feb-2020)
%
% See also:
% fs_preproc

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

if ischar(t1list)
    t1list = {t1list};
end

fscmd = sprintf('recon-all%s -s %s %s-all', ...
    sprintf(' -i %s', t1list{:}), subjCode, t2cmd);

if runcmd
    isnotok = system(fscmd);
    isok = ~isnotok;
else
    isok = 0;
end

end