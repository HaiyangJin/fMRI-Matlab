function fs_processbeta(sessList, anaList, varargin)
% fs_processbeta(sessList, anaList, varargin)
%
% Generate the t-value ('betat.nii.gz') or percentage ('betapct.nii.gz')
% response files for beta-value files. 
%
% Inputs:
%    sessList       <cell str> a list of session codes.
%    anaList        <cell str> a list of analysis names.
%
% Varargin:
%    .outfn         <str> generate 'betat' (the beta t-value) [default] or
%                    'betapct' (the beta percentage) in the same folder as
%                    'beta.nii.gz'.
%    .runwise       <boo> load the data analyzed combining all runs
%                    [runwise = 0; default]; load the data analyzed for
%                    each run separately [runwise = 1].
%    .runinfo       <str> the filename of the run file (e.g.,
%                    run_loc.txt.) [Default is '' and then names of all run
%                    folders will be used.]
%               OR  <str cell> a list of all the run names. (e.g.,
%                    {'001', '002', '003'....}.
%    .funcpath      <str> the path to the session folder,
%                    $FUNCTIONALS_DIR by default.
%
% Output:
%    'betat.nii.gz' or 'betapct.nii.gz' in the same folder as
%    'beta.nii.gz'.
%
% Created by Haiyang Jin (2021-10-28)

defaultOpts = struct(...
    'outfn', 'betat', ...
    'runwise', 0, ...
    'runinfo', '', ...
    'funcpath', getenv('FUNCTIONALS_DIR')...
    );

opts = fm_mergestruct(defaultOpts, varargin{:});

% all the combinations of session codes and analyses
[sessCell, anaCell] = fm_ndgrid(sessList, anaList);

% create files for each session and analysis separately
cellfun(@(x,y) sessbeta(x, y, opts), sessCell, anaCell, 'uni', false);

end

%% For each session code and analysis separately
function sessbeta(sessCode, anaName, opts)

boldDir = fullfile(opts.funcpath, sessCode, 'bold');

if opts.runwise
    % create files for each run separately
    runList = cellfun(@(x) sprintf('pr%s', x), ...
        fs_runlist(sessCode, opts.runinfo, opts.funcpath), 'uni', false);

    dirs = fullfile(boldDir, anaName, runList);
else
    % create one file for each analysis
    dirs = fullfile(boldDir, anaName);
end

% output filenames
outfns = {'betat', 'betapct'};
reffns = {'rstd.nii.gz', 'meanfunc.nii.gz'};

if ischar(opts.outfn)
    outint = find(strcmp(outfns, opts.outfn));
else
    outint = opts.outfn;
end

betafiles = fullfile(dirs, 'beta.nii.gz');

% only create files for existing beta files
isexist = cellfun(@(x) logical(exist(x, 'file')), betafiles);
if any(~isexist)
    nofiles = betafiles(~isexist);
    warning('\n%s cannot be found and will be skipped.', nofiles{:});
end
reffiles = fullfile(dirs(isexist), reffns{outint});

% create files for each beta files separately
cellfun(@(x,y,z) processbeta(x, y, outfns{outint}, z, fm_2hemi(anaName)), ...
    betafiles(isexist), reffiles, dirs(isexist), 'uni', false);

end

%% For each run/analysis separately
function processbeta(betaFile, refFile, outFn, outPath, hemi)

% output data
outData = fs_readfunc(betaFile) ./ fs_readfunc(refFile);

% read beta.nii.gz as template
[~, hdr] = fm_readimg(betaFile);

% only update .vol
hdr.vol = outData;

% save the nifti files
if size(outData,1) == 163842
    % save as .mgz for fsaverage
    fs_savemgz('fsaverage', outData, outFn, outPath, hemi);
else
    save_nifti(hdr,[outFn, '.nii.gz'])
end

end