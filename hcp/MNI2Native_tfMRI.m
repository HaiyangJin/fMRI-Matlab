function MNI2Native_tfMRI(hcpPath, projectString)
% This function was built based on MNI2Native.sh (created by Osama Abdullah
% on 9/9/18), which converts the functional (bold) data from MNI space to
% native space (with FSL functions).
%
% Inputs:
%    hcpPath       path to the HCP results ('Path/to/HCP/') [Default is the
%                   current working directory]
%    sessStr        strings (or prefix) for session information (e.g.,
%                   'faceword' is the prefix for 'faceword01', 'faceword02',
%                   'faceword03'. sessStr will help to identify all the 
%                   session folders. In order to perform this
%                   transformation for only one session, just set the sessStr 
%                   as the full name of the session name (e.g., 'faceword01').
% Output:
%    files of functional (bold) data on native space.  
% Dependency:
%    FSL  (Please make sure FSL is installed and sourced properly.)
%
% Created by Haiyang Jin (5/01/2020) (Based on MNI2Native.sh which was 
% created by Osama Abdullah on 9/09/18).

% check if FSL is sourced properly
if isempty(getenv('FSLDIR'))
    error('Please make sure FSL is installed and sourced properly.');
end

if nargin < 1 || isempty(hcpPath)
    hcpPath = '.';
end
if nargin < 2 || isempty(projectString) || strcmp(projectString, '.')
    
    % all the folders in HCP path
    tempDir = dir(hcpPath);
    tempList = {tempDir.name};
    
    % the string parts of all folder names
    numericParts =  regexp(tempList, '\d+', 'match');
    stringParts = cellfun(@(x, y) erase(x, y), tempList, numericParts, 'uni', false);
    
    % information of string parts
    [uc, ~, idc] = unique(stringParts) ;
    counts = histcounts(idc);

    % the most frequent string will be used as the prefix
    [~, whichStr] = max(counts);
    projectString = uc{whichStr};
  
end
% add '*' if last letter is not '*'
if projectString(end) ~= '*' && ~strcmp(projectString, '.')
    projectString = [projectString, '*'];
end


%% identify all sessions (folders) match sessStr
projDir = dir(fullfile(hcpPath, projectString));

% % remove folders whose superfolder (parent folder) is not hcpPath
% sessDir(~strcmp({sessDir.folder}, hcpPath)) = []; 

if isempty(projDir)
    error('No sessions were found for %s in %s.', projectString, hcpPath);
end

subjList = {projDir.name};
nSubj = numel(subjList);

fileType = {'', '_SBRef'};

for iSubj = 1:nSubj
    
    thisSubj = subjList{iSubj};
    thisPath = fullfile(hcpPath, thisSubj);
    
    %% downsample T2w in native space to fMRI resolution
    cmd_flirt = sprintf(['flirt -in %1$s/T1w/T2w_acpc_dc_restore_brain '...
        '-ref %1$s/T1w/T2w_acpc_dc_restore_brain -applyisoxfm 2 '...
        '-out %1$s/T1w/T2w_acpc_dc_restore_brain_2mm'], thisPath);
    system(cmd_flirt);
    
    %% transform BOLD data from MNI space to Native Space
    resultsPath = fullfile(thisPath, 'MNINonLinear', 'Results');
    mniDir = dir(fullfile(resultsPath, '*fMRI_*'));
    mniList = {mniDir.name};

    % filenames of all bold data to be transformed
    minArray = repmat(mniList, numel(fileType), 1);
    fileArray = repmat(fileType', 1, numel(mniList));
    filenameMNI = cellfun(@(x, y) fullfile(resultsPath, x, [x,y]), minArray(:), fileArray(:), 'uni', false');
    
    % the cell of all functions
    cmds = cellfun(@(x) sprintf(['echo "Transforming from MNI to Native: "%1$s.nii.gz;'...
        'applywarp --rel --interp=trilinear '...
        '-i %1$s.nii.gz -r %2$s/T1w/T2w_acpc_dc_restore_brain_2mm '...
        '-w %2$s/MNINonLinear/xfms/standard2acpc_dc -o %1$s_native.nii.gz'],...
        x, thisPath), filenameMNI, 'uni', false);
    % run all functions
    cellfun(@system, cmds);

end

end