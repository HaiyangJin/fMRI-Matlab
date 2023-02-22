function cmdcell = fm_2cmdpath(cmdcell, varargin)
% cmdcell = fm_2cmdpath(cmdcell)
%
% This function clean the cmd to make it compatible with shell.
%
% Input:
%    cmdcell     <cell str> cmd to be run in shell (before cleaning).
%
% Varargin:
%    ...         the odd argument (in varargin) is the strings to be 
%                replaced and the even argument (in varargin) is the
%                strings to be replaced with.
%
% Output:
%    cmdcell     <cell str> cmd to be run in shell (after cleaning).
%
% Created by Haiyang Jin (2021-10-05)

extrapairs = reshape(varargin, 2, length(varargin)/2)';

asstr = 0;
if ~iscell(cmdcell)
    cmdcell = {cmdcell};
    asstr = 1;
end

defaultpairs = {...
    ' ', '\ ';
    '(', '\(';
    ')', '\)';
    '~', '$HOME'};
reppairs = vertcat(defaultpairs, extrapairs);
nRow = size(reppairs, 1);

for i = 1:nRow
    % replace strings for each pair (row) separately
    cmdcell = cellfun(@(x) strrep(x, reppairs{i, 1}, reppairs{i, 2}), ...
        cmdcell, 'uni', false); 
end

if asstr
    cmdcell = cmdcell{1};
end

end