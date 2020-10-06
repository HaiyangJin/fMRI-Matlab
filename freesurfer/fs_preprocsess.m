function [fscmd, isok] = fs_preprocsess(sessList)
% [fscmd, isok] = fs_preprocsess(sessList)
%
% This function pre-processes the functional data with FreeSurfer (with
% default settings).
% Default setting (bold signal; both hemisphere surface and subcortical; no
% smothing; runwise).
%
% Input:
%    sessList       <string cell> list of session names or the session file.
%
% Output:
%    fscmd          <string> FreeSurfer commands.
%    isok           <logical> whether the command works properly.
%    Preprocessed functional data saved in $FUNCTIONALS_DIR.
%
% Created by Haiyang Jin (6-Oct-2020)
% 
% See also: 
% fs_recon.m

% if sessList is a session file and exists
if exist(sessList, 'dir')
    fscmd_sess = {sprintf('-sf %s ', sessList)};
elseif ischar(sessList)
    sessList = {sessList};
    fscmd_sess = cellfun(@(x) sprintf('-s %s', x), sessList, 'uni', false);
end

% create the FreeSurfer command
fscmd = cellfun(@(x) sprintf(['preproc-sess %s -fsd bold -surface self lhrh ' ...
    '-mni305 -fwhm 0 -per-run -force'], x), fscmd_sess, 'uni', false);

% run the command
isnotok = cellfun(@system, fscmd);
isok = ~isnotok;

end