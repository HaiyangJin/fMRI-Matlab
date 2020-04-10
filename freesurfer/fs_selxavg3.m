function fscmd = fs_selxavg3(sessidfile, anaList)
% fscmd = fs_selxavg3(sessidfile, anaList)
%
% This function runs the first-level analysis for all analysis and contrasts.
%
% Inputs:
%    sessidfile         <string> filename of the session id file. the file 
%                        contains all session codes.
%    anaList            <cell of strings> the list of analysis names.
%
% Output:
%    fscmd              <cell of string> FreeSurfer commands run in the
%                        current session.
%
% Created by Haiyang Jin (19-Dec-2019)

% created the commands
fscmd = cellfun(@(x) sprintf('selxavg3-sess -sf %s -analysis %s -force', ...
    sessidfile, x), anaList, 'uni', false);

% run the analysis
isnotok = cellfun(@system, fscmd);
assert(all(~isnotok), 'Some commands (selxavg3-sess) failed.');

fscmd = fscmd(:);

end