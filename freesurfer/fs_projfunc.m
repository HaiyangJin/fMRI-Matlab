function fscmd = fs_projfunc(sessCode, projFile, runFolder, template, hemi, sm, funcPath)
% fscmd = fs_projfunc(sessCode, projFile, runFolder, template, hemi, sm, funcPath)
%
% This function projects the preprocessed functional (voxelwise) data to 
% fsaverage or self surface. Then FWHM smoothing is applied if needed. The
% output files are:
%     fmcpr.*.[template].sm0.*.?h.nii.gz
%     fmcpr.*.[template].sm5.*.?h.nii.gz (if smoothing is applied)
%
% Inputs:
%     sessCode         <string> session code in funcPath.
%     projFile         <string> the name of the to-be-projected file 
%                       (i.e., the preprocessed functional data).
%                       [do not need to include '.nii.gz'.] 
%     runFolder        <string> the run folder name.
%     template         <string> 'fsaverage' or 'self'. fsaverage is the default.
%     hemi             <string> which hemisphere. 'lh' (default) or 'rh'. 
%     sm               <integer> smoothing with FWHM.
%     funcPath         <string> the full path to the functional folder.
%
% Output:
%     fscmd            <cell of strings> FreeSurfer commands used here.
%
% Created by Haiyang Jin (7-Apr-2020)

projBasename = erase(projFile, '.nii.gz');
projFile = [projBasename '.nii.gz'];

if nargin < 4 || isempty(template)
    template = 'fsaverage';
    warning('The template was not specified and fsaverage will be used by default.');
elseif ~ismember(template, {'fsaverage', 'self'})
    error('The template has to be ''fsaverage'' or ''self'' (not ''%s'').', template);
end

if nargin < 5 || isempty(hemi)
    hemi = 'lh';
    warning(['Hemisphere was not specified and the brain mask will be '...
        'created for the left hemisphere (lh) by default.']);
end

if nargin < 6 || isempty(sm)
    sm = 0;
end

if nargin < 7 || isempty(funcPath)
    funcPath = getenv('FUNCTIONALS_DIR');
end

% empty cell for saving FreeSurfer commands
fscmd = cell(1 + logical(sm), 1);

% target subject code and name
trgSubj = fs_trgsubj(fs_subjcode(sessCode, funcPath), template);

% full path to the run folder
runPath = fullfile(funcPath, sessCode, 'bold', runFolder, filesep);

% full filename of the output file
outFnString = '%s.sm%d.%s.%s.nii.gz';
out0Fn = sprintf(outFnString, projBasename, 0, template, hemi);

%% Project the functional volume data to the surface
% to be compatible with old FreeSurfer version
regFile = fullfile(runPath, 'register.dof6.lta');
if ~exist(regFile, 'file')
    regFile = strrep(regFile, '.lta', '.dat');
end

%%%%%% Project the data. e.g., fmcpr -> fmcpr.sm0  %%%%%%%%
fscmd1 = sprintf(['mri_vol2surf --mov %1$s%2$s ',...
    '--reg %6$s --trgsubject %3$s --interp trilin '...
    '--projfrac 0.5 --hemi %4$s --o %1$s%5$s --noreshape --cortex'],...
    runPath, projFile, trgSubj, hemi, out0Fn, regFile);
fscmd{1, 1} = fscmd1;
isnotok = system(fscmd1);
assert(~logical(isnotok), 'Command (%s) failed.', fscmd1); 

%%%%%% Apply smoothing. e.g., fmcpr.sm0 -> fmcpr.sm5  %%%%%%%%
if sm > 0
    outFn = sprintf(outFnString, projBasename, sm, template, hemi);
    maskFn = sprintf('brain.%s.%s.nii.gz', template, hemi);
    
    fscmd2 = sprintf(['mris_fwhm --s %2$s --hemi %3$s --smooth-only '...
        '--i %1$s%4$s --fwhm %5$d --o %1$s%6$s '...
        '--mask %1$smasks/%7$s --no-detrend'], ...
        runPath, trgSubj, hemi, out0Fn, sm, outFn, maskFn);
    fscmd{2, 1} = fscmd2;
    isnotok = system(fscmd2);
    assert(~logical(isnotok), 'Command (%s) failed.', fscmd2); 

end

end