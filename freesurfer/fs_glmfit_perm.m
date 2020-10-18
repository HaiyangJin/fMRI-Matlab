function fscmd = fs_glmfit_perm(glmdir, varargin)
% fscmd = fs_glmfit_perm(glmdir, varargin)
%
% This function runs permutation to calculate the "p-values" (via
% mri_glmfit-sim).
%
% Inputs:
%    glmdir        <string> or <cell of strings> path to the glmdir
%                   folders. This can be obtained from fs_glmfit_osgm.m.
%                   [glmdir is the current folder by default.]
%
% Varargin:
%    'ncores'      <integer> number of jobs to be used for the simulation
%                   (i.e., the simulation [permutation] are divided into
%                   njobs). [Default is 1].
%    'nsim'        <integer> number of simulations. [Default is 5000].
%    'vwthrehold'  <numeric> voxel[vertex]-wise (clutering form) threshold.
%                   -log(p). [Default is 3 (i.e., p < .01)].
%    'sign'        <string> the direction of the test. ['pos', 'neg',
%                   'abs']. [Default is 'abs'].
%    'cwp'         <numeric> cluster-wise p-value threshold. [Default is
%                   0.05].
%    'spaces'      <integer> 2 or 3. Additional Bonferroni correction
%                   across 2 spaces (eg, lh, rh) or 3 (eg, lh, rh, mni305).
%                   [Default is 2].
%    'runcmd'      <logical> 1: overwrite the permuation[Default]. 2: do 
%                   not overwrite the permutation run before. 0: do not run
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

defaultOpts = struct(...
    'ncores', 1, ...
    'nsim', 5000, ...
    'vwthrehold', 3, ... % voxel-wise (clutering form) threshold
    'sign', 'abs', ...
    'cwp', .05, ... % cluster-wise p-value threshold
    'spaces', 2, ...
    'runcmd', 1 ...
    );

opts = fs_mergestruct(defaultOpts, varargin{:});

ow = {'', ' --overwrite', ''};
owArg = ow{opts.runcmd + 1};

% parameters for permutation
bg = sprintf(' --bg %d', opts.ncores);
perm = sprintf('%d %d %s', opts.nsim, opts.vwthrehold, opts.sign);

% create FreeSurfer commands
fscmd = cellfun(@(x) sprintf(['mri_glmfit-sim --glmdir %s --perm %s '...
    ' --cwp %d  --%dspaces %s%s'], x, perm, opts.cwp, opts.spaces, bg, owArg), ...
    glmdir, 'uni', false);

if opts.runcmd ~= 0
    % run FreeSurfer commands
    isnotok = cellfun(@system, fscmd);
else
    % do not run fscmd
    isnotok = zeros(size(fscmd));
end

% make the fscmd one column
fscmd = [fscmd; num2cell(isnotok)]';

if any(isnotok)
    warning('Some FreeSurfer commands (mri_glmfit) failed.');
elseif opts.runcmd ~= 0
    fprintf('\nmri_glmfit-sim finished without error.\n');
end

end