function [fscmd, isok] = fs_recon(t1File, subjCode, t2File)
% [fscmd, isok] = fs_recon(t1File, subjCode, t2File)
% 
% This function run 'recon-all' in FreeSurfer.
%
% Inputs:
%    t1File       <str> the path to the T1 file.
%    subjCode     <str> subject code.
%    t2File       <str> (optional) the path to the T2 file.
%
% Output:
%    fscmd        <str> FreeSurfer commands.
%    isok         <boo> whether the command works properly.
%    Projected structural data saved in $SUBJECTS_DIR.
%
% Created by Haiyang Jin (6-Feb-2020)
%
% See also: 
% fs_preprocsess

if ~exist('t2File', 'var') || isempty(t2File)
    warning('T2 will not be used during recon-all for %s.', subjCode);
    t2cmd = '';
else
    t2cmd = sprintf('-T2 %s', t2File);
end

fscmd = sprintf('recon-all -i %s -s %s %s -all', t1File, subjCode, t2cmd);
isnotok = system(fscmd);
isok = ~isnotok;

end