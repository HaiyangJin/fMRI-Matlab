function fscmd = fs_selxavg3(sessidfile, anaList, runwise, overwrite, allCPU)
% fscmd = fs_selxavg3(sessidfile, anaList, [runwise = 0, overwrite = 0, allCPU = 0])
%
% This function runs the first-level analysis for all analysis and contrasts.
%
% Inputs:
%    sessidfile         <string> filename of the session id file. the file 
%                        contains all session codes.
%    anaList            <cell of strings> the list of analysis names.
%    runwise            <logical> 0: run the first-level analysis for all 
%                        runs together [default]; 1: run the analysis for
%                        each run separately.
%    overwrite          <logical> 0: do not overwrite [default]; 1:
%                        overwrite the old results; 2: do not run but only
%                        output fscmd.
%    ncores             <logical> 0: only use one CPU [default]; 1: use all 
%                        CPUs. 
%
% Output:
%    fscmd              <cell of string> FreeSurfer commands run in the
%                        current session.
%
% Created by Haiyang Jin (19-Dec-2019)

% argument for -run-wise
if ~exist('runwise', 'var') || isempty(runwise)
    runwise = 0;
end
run = {'', ' -run-wise'};
runArg = run{runwise + 1};

% argument for -overwrite
if ~exist('overwrite', 'var') || isempty(overwrite)
    overwrite = 0;
end
ow = {'', ' -overwrite', ''};
owArg = ow{overwrite + 1};

% argument for -max-threads
if ~exist('allCPU', 'var') || isempty(allCPU)
    allCPU = 0;
end
cpu = {'', ' -max-threads'};
cpuArg = cpu{allCPU + 1};

% combine the "other" arguments
otherArg = sprintf('%s%s%s', owArg, runArg, cpuArg);

%% Create the FreeSurfer commands
fscmd = cellfun(@(x) sprintf('selxavg3-sess -sf %s -analysis %s %s', ...
    sessidfile, x, otherArg), anaList, 'uni', false);

if overwrite ~= 2
    % run the analysis
    isnotok = cellfun(@system, fscmd);
    if any(isnotok)
        warning('Some FreeSurfer commands (selxavg3-sess) failed.');
    end
else
    % do not run fscmd
    isnotok = zeros(size(fscmd));
end

% make the fscmd one column
fscmd = [fscmd; num2cell(isnotok)]';

end