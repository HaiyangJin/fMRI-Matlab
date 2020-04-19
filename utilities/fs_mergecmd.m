function fscmd = fs_mergecmd(varargin)
% fscmd = fs_mergecmd(varargin)
% 
% This function converts varargin into FreeSurfer commands. The 'dash(-)'
% has to be added at the beginning of the variable/field/argument name. If
% there is a corresponding value for that argument, just add it behind that
% argument. (Maybe this is useless.)
%
% Example:
% fs_mergecmd('-arg1', '-arg2', 123, '-arg4', '-arg5', 'value5');
% The output is ' -arg1 -arg4 -arg2 123 -arg5 value5 ';
%
% Created by Haiyang Jin (19-Apr-2020)

% find which of them include "dash" (i.e., argument names)
isDash = false(size(varargin));
isChars = cellfun(@ischar, varargin);
isDash(isChars) = cellfun(@(x) startsWith(x, '-'), varargin(isChars));

%% "Even" commands [Find arguments with values]

% indices for values
evenValue = find(~isDash);

% indices for values and their argument names
evenStrValue = sort([(evenValue -1), evenValue]);

% all the cells for arguments with values
evenCell = varargin(evenStrValue);
nEven = numel(evenCell);
assert(~mod(nEven, 2), 'The number of filed/values has to be even.');

% convert numeric to string
isNum = cellfun(@isnumeric, evenCell);
evenStrCell = evenCell;
evenStrCell(isNum) = cellfun(@num2str, evenCell(isNum), 'uni', false);

% create the commands 
evenCmd = sprintf([' %s %s', repmat(' %s %s', 1, nEven/2)], evenStrCell{:});

%% "Single" commands [arguments only]
% find cells for arguments only
isSingle = ~ismember(1:numel(varargin), evenStrValue);
aloneCell = varargin(isSingle);

% create the commands
aloneCmd = sprintf([' %s', repmat(' %s', 1, numel(aloneCell)-1)], aloneCell{:});

%% Combine cmd
fscmd = [aloneCmd evenCmd];

end