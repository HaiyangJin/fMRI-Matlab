function fscmd = fs_projmask(sessCode, runFolder, template, hemi)
% fscmd = fs_projmask(sessCode, runFolder, template, hemi)
%
% This function projects the brain.nii.gz ($FUNCTIONALS_DIR/sessCode/bold/runDir)
% to the fsaverage or self surface space (without smoothing). It will
% create following files in masks/:
%     brain.[template].?h.pr.nii.gz
%     brain.[template].?h.nii.gz
%
% Inputs:
%     sessCode         <str> session code in $FUNCTIONALS_DIR.
%     runFolder        <str> the run folder name.
%     template         <str> 'fsaverage' or 'self'. fsaverage is the default.
%     hemi             <str> which hemisphere. 'lh' (default) or 'rh'. 
%
% Output:
%     fscmd            <cell str> FreeSurfer commands used here.
%
% Created by Haiyang Jin (7-Apr-2020)
%
% See also:
% fs_projsess.m | fs_projfunc.m

if nargin < 3 || isempty(template)
    template = 'fsaverage';
    warning('The template was not specified and fsaverage will be used by default.');
elseif ~ismember(template, {'fsaverage', 'self'})
    error('The template has to be ''fsaverage'' or ''self'' (not ''%s'').', template);
end

if nargin < 4 || isempty(hemi)
    hemi = 'lh';
    warning(['Hemisphere was not specified and the brain mask will be '...
        'created for the left hemisphere (lh) by default.']);
end

% empty cell for saving FreeSurfer commands
fscmd = cell(2, 1);

% target subject code and name
trgSubj = fs_trgsubj(fs_subjcode(sessCode), template);

% full path to the run folder
runPath = fullfile(getenv('FUNCTIONALS_DIR'), sessCode, 'bold', runFolder, filesep);

% full filename of the output file
outprFilename = fullfile(runPath, 'masks', sprintf('brain.%s.%s.pr.nii.gz', template, hemi));
outFilename = fullfile(runPath, 'masks', sprintf('brain.%s.%s.nii.gz', template, hemi));

%% Create the brain mask
%%%%%%%% project brain.nii.gz to brain.self.rh.pr.nii.gz %%%%%%
fscmd1 = sprintf(['mri_vol2surf --mov %1$smasks/brain.nii.gz '...
    '--reg %1$sregister.dof6.lta '...
    '--trgsubject %2$s --interp nearest --projfrac 0.5 --hemi %3$s '...
    '--o %4$s --noreshape --cortex'], ...
    runPath, trgSubj, hemi, outprFilename);
fscmd{1, 1} = fscmd1;
isnotok = system(fscmd1);
assert(~isnotok, 'Command (%s) failed.', fscmd1); 

%%%%%%%% binarize brain.self.rh.pr.nii.gz %%%%%%
fscmd2 = sprintf('mri_binarize --i %1$s --min .00001 --o %1$s', outprFilename);
fscmd{2, 1} = fscmd2;
isnotok = system(fscmd2);
assert(~isnotok, 'Command (%s) failed.', fscmd2); 


%% Copy *.pr.nii.gz to *.nii.gz
% e.g., copy brain.self.rh.pr.nii.gz to brain.self.rh.nii.gz
copyfile(outprFilename, outFilename); 

end