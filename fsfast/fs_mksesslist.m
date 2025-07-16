function fs_mksesslist(sesswd, sessfn, sesspath)
% fs_mksesslist(sesswd, sessfn, sesspath)
%
% Make a session list.
%
% Inputs:
%    sessfn      <str> session list file name. Default to
%    sesspath    <str> where to save the session file. Default to
%                 $FUNCTIONALS_DIR. If $FUNCTIONALS_DIR is empty, default
%                 to the current working directory.
%
% Output:
%    a generated session list files.
%
% Created by Haiyang Jin (2025-June-4)

if ~exist('sesswd', 'var') || isempty(sesswd)
    sesswd = 'sub-*';
end

if ~exist('sessfn', 'var') || isempty(sessfn)
    sessfn = 'sesslist';
end

if ~exist('sesspath', 'var') || isempty(sesspath)

    sesspath = getenv('FUNCTIONALS_DIR');
    if isempty(sesspath)
        sesspath = pwd;
    end
end

% find matching functionals
sessdir = dir(fullfile(sesspath, sesswd));
% get the list of functionals
sesslist = {sessdir.name};

if size(sesslist, 1) == 1
    sesslist = sesslist';
end

% make the session file
fm_mkfile(fullfile(sesspath, sessfn), sesslist);

end