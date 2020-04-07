function fscmd = fs_sessmeanmask(sessCode, tofsavg, funcPath)
% fscmd = fs_sessmeanmask(sessCode, tofsavg, funcPath)
%
% This function generates the mean mask of all run masks within that session. 
% Its outputs are:
%     boldPath/masks/brain.*.?h.pr.nii.gz
%
% Inputs:
%     sessCode         <string> session code in funcPath.
%     toFsavg          <logical> 1: fsaverage will be used as the target; 
%                       0: self surface will be used as the target.
%                       fsaverage will be used by default.
%     funcPath         <string> the full path to the functional folder.
%
% Output:
%     fscmd            <cell of strings> FreeSurfer commands used here.
%
% Created by Haiyang Jin (7-Apr-2020)

if nargin < 2 || isempty(tofsavg)
    tofsavg = 1;
    warning('Target subject was not specified and fsaverage will be used by default.');
end

if nargin < 3 || isempty(funcPath)
    funcPath = getenv('FUNCTIONALS_DIR');
end

% hemispheres
hemis = {'lh', 'rh'};
nHemi = numel(hemis);

% target subject code and name
trgNames = {'fsaverage', 'self'};
trgName = trgNames{2-tofsavg};

% empty cell for saving FreeSurfer commands
fscmd = cell(2, nHemi);

% run information
runList = fs_runlist(sessCode, funcPath);
nRun = numel(runList);

% bold path
boldPath = fullfile(funcPath, sessCode, 'bold');
    
% calculate the mean mask for each hemisphere separately
for iHemi = 1:nHemi
    
    maskFn = sprintf('brain.%s.%s.pr.nii.gz', trgName, hemis{iHemi});
    maskFilename = fullfile(boldPath, 'masks', maskFn);
    
    masks = fullfile(boldPath, runList, 'masks', maskFn);
    
    % calcuate the mean masks
    fscmd1 = sprintf(['mri_concat --o %s --mean' repmat(' %s', 1, nRun)], ...
        maskFilename, masks{:});
    fscmd{1, 1} = fscmd1;
    system(fscmd1)
    
    % binary the masks
    fscmd2 = sprintf('mri_binarize --i %1$s --min 10e-10 --o %1$s', maskFilename);
    fscmd{2, 1} = fscmd2;
    system(fscmd2)
    
end

% save the FreeSurfer commands as one column
fscmd = reshape(fscmd, [], 1);

end