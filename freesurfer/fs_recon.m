function [fscmd, isok] = fs_recon(t1File, subjCode)
% [fscmd, isok] = fs_recon(t1File, subjCode)
% 
% This function run 'recon-all' in FreeSurfer
%
% Inputs:
%    t1File       <string> the path to the T1 file
%    subjCode     <string> subject code
%
% Output:
%    fscmd        <string> FreeSurfer commands.
%    isok         <logical> whether the command works properly.
%    Projected structural data saved in $SUBJECTS_DIR.
%
% Created by Haiyang Jin (6-Feb-2020)
%
% See also: 
% fs_preprocsess.m

fscmd = sprintf('recon-all -i %s -s %s -all', t1File, subjCode);
isnotok = system(fscmd);
isok = ~isnotok;

end