function [fscmd, isok] = fs_preproc(sessCode, sm, template, extracmd, runcmd)
% [fscmd, isok] = fs_preproc(sessCode, sm, template extracmd)
%
% This function pre-processes the functional data with FreeSurfer (with
% default settings).
% Default setting (bold signal; both hemisphere surface and subcortical; no
% smothing; runwise).
%
% Input:
%    sessCode       <str> session code (folders).
%                OR <str> the session file.
%    sm             <int> smoothing. Default is 0 (i.e., no smoothing).
%    template       <str> surface template: 'self' [default], 'fsaverage',
%                    'fsaverage5'. 
%    extracmd       <str> extra commands to be added for preproc-sess.
%    runcmd         <boo> whether to run the recon-all commands [default: 1].
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

if exist(sessCode, 'dir') == 7
    % if sessCode is a session folder and exists
    fscmd_sess = sprintf('-s %s', sessCode);
elseif ~exist(sessCode, 'file')
    error('Cannot find %s in %s...', sessCode, pwd);
else
    fscmd_sess = sprintf('-sf %s ', sessCode);
end

if ~exist('sm', 'var') || isempty(sm)
    sm = 0;
end

if ~exist('template', 'var') || isempty(template)
    template = 'self';
end

if ~exist('extracmd', 'var') || isempty(extracmd)
    extracmd = '';
end

if ~exist('runcmd', 'var') || isempty(runcmd)
    runcmd = 1;
end

% create the FreeSurfer command
fscmd = sprintf(['preproc-sess %s -fsd bold -surface %s lhrh ' ...
    '-mni305 -fwhm %d -per-run -nostc %s -force'], ...
    fscmd_sess, template, sm, extracmd);

% run the command
if runcmd
    isnotok = system(fscmd);
    isok = ~isnotok;
else
    isok = 0;
end

end