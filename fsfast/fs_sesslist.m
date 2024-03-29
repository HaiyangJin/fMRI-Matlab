function sessList = fs_sesslist(sessid)
% sessList = fs_sesslist(sessid)
%
% This function reads the session ID file and output the session list.
%
% Inputs:
%    sessid           <str> name of the sessiond id file. OR the full
%                      name of the session id file (with path).
%
% Output:
%    sessList         <cell str> a list of session names.
% 
% Created by Haiyang Jin (7-Apr-2020)

if nargin < 1 || isempty(sessid)
    sessid = 'sessid*';
end
    
if isempty(fileparts(sessid))    
    % dir all the possible session files
    sessDir = dir(fullfile(getenv('FUNCTIONALS_DIR'), sessid));
    nID = numel(sessDir);
    
    % error if there are multiple session files
    if nID > 1
        error(['There are %d session ID files. Please specify which '...
            'you want to use.'], nID);
    elseif nID == 0
        error('Cannot find the session id file (%s).', sessid);
    else
        % create the session id filename (with path)
        sessFilename = fullfile(sessDir.folder, sessDir.name);
    end
    
else
    % save the session id filename (with path)
    sessFilename = sessid;
end

assert(logical(exist(sessFilename, 'file')), ...
    'Cannot find the session id file (%s).', sessFilename);

% read the session id file
sessList = fm_readtext(sessFilename);

end