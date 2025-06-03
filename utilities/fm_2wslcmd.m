function wslcell = fm_2wslcmd(cmdcell)
% wslcell = fm_2wslcmd(cmdcell)
%
% Convert cmds generated with Windows into WSL (Linux).
%
% Inputs: 
%     cmdcell     <cell str> a list of cmd.
%
% Output:
%     wslcell     <cell str> a list of cmd compatible with WSL.
%
% Created by Haiyang Jin (2025-June-2)

tochar = 0;
if ischar(cmdcell)
    cmdcell = {cmdcell}; 
    tochar = 1;
end

% update cmd
wslcell = cellfun(@win2wsl, cmdcell, 'uni', false);

if tochar
    wslcell = wslcell{1};
end

end


function cmd = win2wsl(cmd)

% Find all matches
matches = unique(regexp(cmd, ' [a-zA-Z]:[\\/]', 'match'));
if size(matches, 1)==1; matches = matches'; end

% target format
wsldisk = cellfun(@(x) sprintf(' /mnt/%s/', lower(x(2))), matches, 'uni', false);

reppairs = horzcat(matches, wsldisk);

for i = 1:size(reppairs, 1)
    cmd = strrep(cmd, reppairs{i, 1}, reppairs{i, 2});
end
cmd = strrep(cmd, '\', '/');

end
