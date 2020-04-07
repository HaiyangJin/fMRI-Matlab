function sessList = fs_sesslist(sessid, funcPath)
% sessList = fs_sesslist(sessid, funcPath)
%
% This function reads the session ID file and output the session list.
%
% Inputs:
%    sessid           <string> name of the sessiond id file. OR the full
%                      name of the session id file (with path).
%    funcPath         <string> the full path to the functional folder.
%
% Output:
%    sessList         <cell of string> a list of session names.
% 
% Created by Haiyang Jin (7-Apr-2020)

if nargin < 1 || isempty(sessid)
    sessid = 'sessid*';
end
    
if isempty(fileparts(sessid))
    % if there is no path included in sessid
    
    if nargin < 2 || isempty(funcPath)
        funcPath = getenv('FUNCTIONALS_DIR');
    end
    
    % dir all the possible session files
    sessDir = dir(fullfile(funcPath, sessid));
    nID = numel(sessDir);
    
    % error if there are multiple session files
    if nID > 1
        error(['There are %d session ID files. Please specify which '...
            'you want to use.'], nID);
    else
        % create the session id filename (with path)
        sessFilename = fullfile(sessDir.folder, sessDir.name);
    end
    
else
    % save the session id filename (with path)
    sessFilename = sessid;
end

% read the session id file
sessList = fs_readtext(sessFilename);

end