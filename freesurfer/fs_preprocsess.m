function [fscmd, isok] = fs_preprocsess(sessCode, sm, extracmd)
% [fscmd, isok] = fs_preprocsess(sessCode, sm, extracmd)
%
% This function pre-processes the functional data with FreeSurfer (with
% default settings).
% Default setting (bold signal; both hemisphere surface and subcortical; no
% smothing; runwise).
%
% Input:
%    sessCode       <str> session code.
%                OR <str> the session file.
%    sm             <int> smoothing. Default is 0 (i.e., no smoothing).
%    extracmd       <str> extra commands to be added.
%
% Output:
%    fscmd          <str> FreeSurfer commands.
%    isok           <boo> whether the command works properly.
%    Preprocessed functional data saved in $FUNCTIONALS_DIR.
%
% Created by Haiyang Jin (6-Oct-2020)
% 
% See also: 
% [fs_recon;] fs_mkanalysis;

% if sessList is a session file and exists
if exist(sessCode, 'file')
    fscmd_sess = sprintf('-sf %s ', sessCode);
else
    fscmd_sess = sprintf('-s %s', sessCode);
end

if ~exist('sm', 'var') || isempty(sm)
    sm = 0;
end

if ~exist('extracmd', 'var') || isempty(extracmd)
    extracmd = '';
end

% create the FreeSurfer command
fscmd = sprintf(['preproc-sess %s -fsd bold -surface self lhrh ' ...
    '-mni305 -fwhm %d -per-run -nostc %s -force'], fscmd_sess, sm, extracmd);

% run the command
isnotok = system(fscmd);
isok = ~isnotok;

end