function fscmd = fs_selxavg3(sessidfile, anaList, runwise, runcmd, allCPU)
% fscmd = fs_selxavg3(sessidfile, anaList, runwise, runcmd, allCPU)
%
% This function runs the first-level analysis for all analysis and contrasts.
%
% Inputs:
%    sessidfile         <str> filename of the session id file. the file 
%                        contains all session codes.
%                   OR  <str> sessid (for -s).
%    anaList            <cell str> the list of analysis names.
%    runwise            <boo> 0: run the first-level analysis for all 
%                        runs together [default]; 1: run the analysis for
%                        each run separately.
%    runcmd             <boo> 2: do not overwrite [default]; 1: run and
%                        overwrite the old results; 0: do not run but only
%                        output fscmd.
%    ncores             <boo> 0: only use one CPU [default]; 1: use all 
%                        CPUs. 
%
% Output:
%    fscmd              <cell str> FreeSurfer commands run in the
%                        current session.
%
% Created by Haiyang Jin (19-Dec-2019)
%
% See also:
% [fs_mkcontrast;] fs_isxconcat; fs_cvn_print1st

if nargin < 1
    fprintf('Usage: fscmd = fs_selxavg3(sessidfile, anaList, runwise, runcmd, allCPU);\n');
    return;
end

assert(ischar(sessidfile), '<sessidfile> has to be a string or char.');

if exist(sessidfile, 'dir')
    % will be used as sessid
    sess_cmd = sprintf('-s %s', sessidfile);
else
    % will be used as sessidfile
    sess_cmd = sprintf('-sf %s', sessidfile);
end

% argument for -run-wise
if ~exist('runwise', 'var') || isempty(runwise)
    runwise = 0;
end
run = {'', ' -run-wise'};
runArg = run{runwise + 1};

% argument for -overwrite
if ~exist('runcmd', 'var') || isempty(runcmd)
    runcmd = 2;
end
ow = {'', ' -overwrite', ''};
owArg = ow{runcmd + 1};

% argument for -max-threads
if ~exist('allCPU', 'var') || isempty(allCPU)
    allCPU = 0;
end
cpu = {'', ' -max-threads'};
cpuArg = cpu{allCPU + 1};

% combine the "other" arguments
otherArg = sprintf('%s%s%s', owArg, runArg, cpuArg);

%% Create the FreeSurfer commands
fscmd = cellfun(@(x) sprintf('selxavg3-sess %s -analysis %s %s', ...
    sess_cmd, x, otherArg), anaList(:), 'uni', false)';

[fscmd, isnotok] = fm_runcmd(fscmd, runcmd);

if any(isnotok)
    warning('Some FreeSurfer commands (selxavg3-sess) failed.');
elseif runcmd ~= 0
    fprintf('\nselxavg3-sess finished without error.\n');
end

end