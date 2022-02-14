function [cmdout, isnotok] = fm_runcmd(cmd, runcmd)
% [cmdout, isnotok] = fm_runcmd(cmd, runcmd)
%
% Runs cmd.
%
% Inputs:
%    cmd         <cell str> a list of cmd to be run.
%    runcmd      <boo> whether to run the cmd.
%
% Output:
%    cmdout      <cell> the first column is the cmd and the second column
%                 is whether the cmd is run without error (0).
%    isnotok     <vec> whether the cmd were run without error.
%
% Created by Haiyang Jin (2022-02-14)

if nargin < 1
    fprintf('Usage: [cmdout, isnotok] = fm_runcmd(cmd, runcmd);\n');
    return;
elseif ischar(cmd)
    cmd = {cmd};
end
cmd = cmd(:); % make it to a column

if ~exist('runcmd', 'var') || isempty(runcmd)
    runcmd = 1;
end

% run or not running cmd
if runcmd
    isnotok = cellfun(@system, cmd);
else
    isnotok = zeros(size(cmd));
end

% add isnotok to fscmd
cmdout = horzcat(cmd, num2cell(isnotok));

end
