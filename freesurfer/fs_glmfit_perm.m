function fscmd = fs_glmfit_perm(glmdir, ncores, nSim, vwthrehold, sign, cwp, spaces, overwrite)
% fscmd = fs_glmfit_perm([glmdir = {'.'}, cores = 1, nSim = 5000, ...
%    vwthrehold = 3, sign = 'abs', cwp = 0.05, spaces = 2, overwrite = 1])
%
% This function runs permutation to calculate the "p-values" (via
% mri_glmfit-sim).
%
% Inputs:
%    glmdir        <string> or <cell of strings> path to the glmdir
%                   folders. This can be obtained from fs_glmfit_osgm.m.
%                   [glmdir is the current folder by default.]
%    ncores        <integer> number of jobs to be used for the simulation
%                   (i.e., the simulation [permutation] are divided into
%                   njobs). [Default is 1].
%    nSim          <integer> number of simulations. [Default is 5000].
%    vwthrehold    <numeric> voxel[vertex]-wise (clutering form) threshold.
%                   -log(p). [Default is 2 (i.e., p < .01)].
%    sign          <string> the direction of the test. ['pos', 'neg',
%                   'abs']. [Default is 'abs'].
%    cwp           <numeric> cluster-wise p-value threshold. [Default is
%                   0.05].
%    spaces        <integer> 2 or 3. Additional Bonferroni correction
%                   across 2 spaces (eg, lh, rh) or 3 (eg, lh, rh, mni305).
%                   [Default is 2].
%    overwrite     <logical> 1: overwrite the permuation. 0: do not
%                   overwrite the permutation run before. 2: do not run
%                   FreeSurfer commands but only output fscmd.
%
% Output:
%    fscmd         <cell of strings> The first column is FreeSurfer
%                   commands used in the current session. And the second
%                   column is whether the command successed.
%                   [0: successed; other numbers: failed.]
%
% Created by Haiyang Jin (12-Apr-2020)

if ~exist('glmdir', 'var') || isempty(glmdir)
    glmdir = {'.'};
elseif ischar(glmdir)
    glmdir = {glmdir};
end
if ~exist('ncores', 'var') || isempty(ncores)
    ncores = 1;
end
if ~exist('nSim', 'var') || isempty(nSim)
    nSim = 5000; % nsim vwthreshold sign
end
if ~exist('vwthrehold', 'var') || isempty(vwthrehold)
    vwthrehold = 3; % voxel-wise (clutering form) threshold
end
if ~exist('sign', 'var') || isempty(sign)
    sign = 'abs';
end
if ~exist('cwp', 'var') || isempty(cwp)
    cwp = .05;  % cluster-wise p-value threshold
end
if ~exist('spaces', 'var') || isempty(spaces)
    spaces = 2;
end
if ~exist('overwrite', 'var') || isempty(overwrite)
    overwrite = 1;
end
ow = {'', ' --overwrite', ''};
owArg = ow{overwrite + 1};

% parameters for permutation
bg = sprintf(' --bg %d', ncores);
perm = sprintf('%d %d %s', nSim, vwthrehold, sign);

% create FreeSurfer commands
fscmd = cellfun(@(x) sprintf(['mri_glmfit-sim --glmdir %s --perm %s '...
    ' --cwp %d  --%dspaces %s%s'], x, perm, cwp, spaces, bg, owArg), ...
    glmdir, 'uni', false);

if overwrite ~= 2
    % run FreeSurfer commands
    isnotok = cellfun(@system, fscmd);
    if any(isnotok)
        warning('Some FreeSurfer commands (mri_glmfit) failed.');
    end
else
    % do not run fscmd
    isnotok = zeros(size(fscmd));
end

% make the fscmd one column
fscmd = [fscmd; num2cell(isnotok)]';

end