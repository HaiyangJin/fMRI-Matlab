function cmdcell = fm_cleancmd(cmdcell)
% cmdcell = fm_cleancmd(cmdcell)
%
% This function clean the cmd to make it compatible with shell.
%
% Input:
%    cmdcell     <cell str> cmd to be run in shell (before cleaning).
%
% Output:
%    cmdcell     <cell str> cmd to be run in shell (after cleaning).
%
% Created by Haiyang Jin (2021-10-05)

asstr = 0;
if ~iscell(cmdcell)
    cmdcell = {cmdcell};
    asstr = 1;
end

spacecell = {...
    'My Drive', 'My\ Drive';
    '~', '{$HOME}'};
nRow = size(spacecell, 1);

for i = 1:nRow
    % replace strings for each pair (row) separately
    cmdcell = cellfun(@(x) strrep(x, spacecell{i, 1}, spacecell{i, 2}), ...
        cmdcell, 'uni', false); 
end

if asstr
    cmdcell = cmdcell{1};
end

end