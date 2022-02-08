function outdir = fs_bids_setup(bidsDir, cd2funcdir)
% fs_bids_setup(bidsDir, cd2funcdir)
%
% Set the $SUBJECTS_DIR and %FUNCTIONALS_DIR for BIDS. 
%
% Inputs:
%    bidsDir      <str> full path to the BIDS direcotry. Default is
%                  bids_dir(). 
%    cd2funcdir   <boo> whehter change the directory to the functionals
%                  directory ($FUNCTIONALS_DIR). Default is 1.
%
% Output:
%    outdir       <struct> the BIDS, $SUBJECTS_DIR, and $FUNCTIONALS_DIR.
%
% Created by Haiyang Jin (2022-02-07)

outdir = struct;

if ~exist('bidsDir', 'var') || isempty(bidsDir)
    bidsDir = bids_dir();
end
outdir.bidsDir = bidsDir;

outdir.struDir = fs_subjdir(fullfile(bidsDir, 'derivatives', 'subjects'));
outdir.funcDir = fs_funcdir(fullfile(bidsDir, 'derivatives', 'functionals'));

% change the working directory if needed
if ~exist('cd2funcdir', 'var') || isempty(cd2funcdir)
    cd2funcdir = 1;
end

if cd2funcdir
    cd(outdir.funcDir);
end

end

