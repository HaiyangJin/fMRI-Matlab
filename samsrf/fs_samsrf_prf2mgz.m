function fs_samsrf_prf2mgz(prfFn, subjCode, contraNum, outFn, outPath)
% fs_samsrf_prf2mgz(prfFn, subjCode, contraNum, outFn, outPath)
%
% This function converts 'Srf' in samsrf (could be the GLM or Prf results)
% to a *.mgz file.
%
% Inputs:
%    prfFn       <string> the prf filename in prf/ folder.
%    subjcode    <string> subject code in $SUBJECTS_DIR.
%    contraNum   <integer> which contrast will be converted. Default is 1.
%    outFn       <string> the filename of the output. Default is the prfFn+
%                 the contrast name.
%    outPath     <string> the path of the output. Default is prf/ folder. 
%
% Output:
%    a *.mgz file in the same folder (by default).
%
% Created by Haiyang Jin (30-Jan-2020)

if ~endsWith(prfFn, '.mat')
    prfFn = [prfFn '.mat'];
end

% load the prf file
prfFilename = fullfile(getenv('SUBJECTS_DIR'), subjCode, 'prf', prfFn);
assert(logical(exist(prfFilename, 'file')), 'Cannot find %s...', prfFilename);

load(prfFilename);

if ~exist('contraNum', 'var') || isempty(contraNum)
    contraNum = 1;
end

if ~exist('outFn', 'var') || isempty(outFn)
    outFn = sprintf('%s_%s.mgz', erase(prfFn, '.mat'), Srf.Values{contraNum,1});
end

if ~exist('outPath', 'var') || isempty(outPath)
    outPath = fullfile(getenv('SUBJECTS_DIR'), subjCode, 'prf');
end

% contrast surf data
surfData = Srf.Data(contraNum, :);

% save the mgz file
hemi = fm_2hemi(prfFn);
fs_savemgz(subjCode, surfData, outFn, outPath, hemi);

end