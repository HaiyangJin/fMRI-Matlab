function [fpcmd, status] = fp_fmriprep(subjCode, varargin)
% [fpcmd, status] = fp_fmriprep(subjCode, varargin)
%
% Run fmriprep with 'fmriprep-docker'. 
% To update `fmriprep-docker`: pip install --user --upgrade fmriprep-docker
% 
% Inputs:
%    subjCode       <str> the subject code (folder) within opts.bidsdir.
%
% Varargin:
%    .fslicense     <str> where the FreeSurfer license is. You need to make
%                    sure the path is accessible by Docker. Default
%                    location is in the Documents/ folder 
%                    ('$HOME/Documents/license.txt').
%    .outspace      <str> a list of spaces, on which data will be
%                    processed. % Available spaces in fmriPrep: 
%                    https://fmriprep.org/en/stable/spaces.html
%    .cifti         <str> spaces in HCP. Default is '91k'. Available
%                    options are [{91k,170k}].
%    .nthreads      <int> number of threads. Default is 8.
%    .maxnthreads   <int> maximum number of threads per-process. Default is
%                    4.
%    .wd            <str> working directory. Default to a folder called 
%                    '*_work/', which is at the same location as `bidsDir`
%                    and '*' is the last level of `bidsDir` folder name.
%                    For example, if the `bidsDir` is 'path/to/bidsDir',
%                    the working directory will be 'path/to/bidsDir_work'.
%    .ignore        <str> steps to be ignored in fmriprep. Available
%                    options are 'fieldmaps,slicetiming,sbref'.
%    .runcmd        <boo> whether to run the command. Default is 1.
%    .path2fmriprep <str> path to `fmriprep_docker` command. Default to ''.
%    .bidsdir       <str> where the BIDS folder is. Default is bids_dir().
%    .extracmd      <str> any other options available in fmriprep. Setting
%                    in 'extracmd' will replace all the above settings.
%                    More see: https://fmriprep.org/en/stable/usage.html
%
% Output:
%    fpcmd          <str> fmriprep-docker commands. 
%    status         <int> the status of running fpcmd.
%
% % Example:
% [fpcmd, status] = fp_fmriprep('sub-01', 'ignore', 'slicetiming');
%
% Created by Haiyang Jin (2021-10-14)
% 
% See also:
% [bids_dcm2bids; bids_mktsv; bids_fixfmap; bids_fixfunc]

%% Deal with inputs
% default settings
defaultOpts = struct(...
    'fslicense', '$HOME/Documents/license.txt', ...
    'outspace', 'fsnative fsaverage6 fsaverage T1w MNI152NLin2009cAsym', ... 
    'cifti', '91k', ... --cifti-output 
    'nthreads', 8, ... % above 8 does not seem to help (further)
    'maxnthreads', 4, ... % maximum number of threads per-process
    'wd', '', ...
    'ignore', '', ... % {fieldmaps,slicetiming,sbref}
    'runcmd', 1, ...
    'path2fmriprep', '', ...
    'bidsdir', bids_dir(), ...
    'extracmd', '' ...
    );
opts = fm_mergestruct(defaultOpts, varargin{:});

if ~exist('subjCode', 'var') || isempty(subjCode)
    error('Please input the subject code.');
elseif ~startsWith(subjCode, 'sub-')
    % make sure subject code starts with 'sub-'
    subjCode = ['sub-' subjCode];
end
% make sure the subject code folder exists
assert(logical(exist(fullfile(opts.bidsdir, subjCode), 'dir')), ...
    'Cannot find subject (%s) in %s', subjCode, opts.bidsdir);

%% Other options
extracell = cell(6, 1);

if ~contains(opts.extracmd, '--output-space')
    extracell{1, 1} = sprintf('--output-space %s', opts.outspace);
end

if ~contains(opts.extracmd, '--cifti-output')
    extracell{2, 1} = sprintf('--cifti-output %s', opts.cifti);
end

if ~contains(opts.extracmd, '--fs-license-file')
    extracell{3, 1} = sprintf(['--fs-license-file %s ' ...
        '--fs-subjects-dir %s/derivatives/freesurfer/'], ...
        opts.fslicense, opts.bidsdir);
end

if isempty(opts.wd)
    if endsWith(opts.bidsdir, filesep)
        opts.wd = [opts.bidsdir(1:end-1) '_work'];
    else
        opts.wd = [opts.bidsdir '_work'];
    end
end
if ~isempty(opts.wd) && ~contains(opts.extracmd, '-w')
    fm_mkdir(fullfile(opts.wd, subjCode));
    extracell{4, 1} = sprintf('-w %s', opts.wd);
end

if ~isempty(opts.ignore) && ~contains(opts.extracmd, '--ignore')
    extracell{5, 1} = ['--ignore ' opts.ignore];
end

if opts.nthreads > 0 && ~contains(opts.extracmd, '--nthreads')
    extracell{6, 1} = sprintf('--nthreads %d', opts.nthreads);
end

if opts.maxnthreads > 0 && ~contains(opts.extracmd, '--omp-nthreads')
    extracell{7, 1} = sprintf('--omp-nthreads %d', opts.maxnthreads);
end

extracmd = sprintf(' %s', extracell{:});

%% The whole fmriprep-docker command
fpcmd = sprintf(['%sfmriprep-docker %s %s/derivatives/fmriprep/ participant ' ...
    '--participant-label %s %s '], ...
    opts.path2fmriprep, opts.bidsdir, opts.bidsdir, subjCode, extracmd);

if opts.runcmd
    % run commands
    status = system(fpcmd);
else
    status = -1;
end

end