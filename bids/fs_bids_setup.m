function outdir = fs_bids_setup(bidsDir, subjDir, funcDir, cd2funcdir)
% outdir = fs_bids_setup(bidsDir, subjDir, funcDir, cd2funcdir)
%
% Set the $SUBJECTS_DIR and %FUNCTIONALS_DIR for BIDS. 
%
% Inputs:
%    bidsDir      <str> full path to the BIDS direcotry. Default is
%                  bids_dir(). 
%    subjDir      <str> $SUBJECTS_DIR in FreeSurfer. Default is
%                  '<bidsDir>/derivatives/subjects'.
%    funcDir      <str> $FUNCTIONALS_DIR in FS-FAST. Default is
%                  '<bidsDir>/derivatives/functionals'.
%    cd2funcdir   <boo> whehter change the directory to the functionals
%                  directory ($FUNCTIONALS_DIR). Default is 1.
%
% Output:
%    outdir       <struct> the BIDS, $SUBJECTS_DIR, and $FUNCTIONALS_DIR.
%
% Created by Haiyang Jin (2022-02-07)

outdir = struct;

if ~exist('bidsDir', 'var') || isempty(bidsDir)
    try
        bidsDir = bids_dir();
    catch
        if nargin<1
            fprintf('Usage: outdir = fs_bids_setup(bidsDir, subjDir, funcDir, cd2funcdir);\n');
            return;
        end
    end
end
bidsDir = bids_dir(bidsDir);
outdir.bidsDir = bidsDir;

if ~exist('subjDir', 'var') || isempty(subjDir)
    subjDir = fs_subjdir(fullfile(bidsDir, 'derivatives', 'subjects'));
end
fm_mkdir(subjDir);
fs_subjdir(subjDir);
outdir.struDir = subjDir;

if ~exist('funcDir', 'var') || isempty(funcDir)
    funcDir = fs_funcdir(fullfile(bidsDir, 'derivatives', 'functionals'));
end
fm_mkdir(funcDir);
fs_funcdir(funcDir);
outdir.funcDir = funcDir;

% change the working directory if needed
if ~exist('cd2funcdir', 'var') || isempty(cd2funcdir)
    cd2funcdir = 1;
end

if cd2funcdir
    cd(outdir.funcDir);
end

end

