function fs_fun_cosmo_searchlight(project, classPairs, sessCode, surfCoorFile, combineHemi, classifier)
% fs_fun_cosmo_searchlight(project, classPairs, sessCode, surfCoorFile, combineHemi, classifier)
% This function does the searchlight analyses for the faceword project
% with CoSMoMVPA. Data were analyzed with FreeSurfer.
%
% Inputs:
%    project            project structure (created by fs_fun_projectinfo)
%    classPairs         condition pairs to be classified
%    sessCode           session code (functional subject folder)
%    surfCoorFile       the coordinate file for vertices ('inflated',
%                       'white', 'pial')
%    combineHemi        if the data of two hemispheres will be combined
%                       (default is no) [0: run searchlight for the two
%                       hemnispheres separately; 1: run searchlight
%                       anlaysis for the whole brain together; 3: run
%                       analysis for both 0 and 1.
%    classifier         classifier function handle
%
% Output:
%    For each hemispheres, the results will be saved as a label file saved
%    at the subject label folder ($SUBJECTS_DIR/subjCode/label)
%    For the whole brain, the results will be saved as *.gii
%
% Created by Haiyang Jin (24-Nov-2019)
% Updated by Haiyang Jin (15-Dec-2019)

cosmo_warning('once');

if nargin < 3 || isempty(sessCode)
    sessList = project.sessList; % all sessions
elseif ischar(sessCode)
    sessList = {sessCode};
else
    sessList = sessCode;
end

if nargin < 4 || isempty(surfCoorFile)
    surfCoorFile = 'inflated';
end
if nargin < 5 || isempty(combineHemi)
    combineHemi = 0;
end
if nargin < 6
    classifier = '';
end

%% Preparation
% waitbar
waitHandle = waitbar(0, 'Loading...   0.00% finished');

% information from the project
nHemi = project.nHemi;
funcPath = project.funcPath;
nSess = numel(sessList);

for iSess = 1:nSess
    %% this subject information
    % subjCode in functional folder
    thisSess = sessList{iSess};
    % subjCode in SUBJECTS_DIR
    subjCode = fs_subjcode(thisSess, funcPath);
    hemis = project.hemis;
    
    % waitbar
    progress = iSess / nSess * 1/2;
    progressMsg = sprintf('Loading data for %s.   \n%0.2f%% finished...', ...
        strrep(subjCode, '_', '\_'), progress*100);
    waitbar(progress, waitHandle, progressMsg);
    
    % load vertex and face coordinates
    [vtxCell, faceCell] = fs_cosmo_surfcoor(subjCode, surfCoorFile, combineHemi);
    
    
    %% Load functional data (beta.nii.gz)
    % load the beta.nii.gz for both hemispheres separately
    [~, dsSurfCell] = cellfun(@(x) fs_fun_uni_cosmo_ds(project, x, thisSess, ...
        '', 'main', 0, 1), hemis, 'UniformOutput', false);
    
    % combine the surface data for the whole brain if needed
    if ~combineHemi
        runSearchlight = 1:nHemi;
    else
        dsSurfCell = [dsSurfCell, cosmo_combinesurf(dsSurfCell)]; %#ok<AGROW>
        hemis = [hemis, 'both']; %#ok<AGROW>
        
        if combineHemi == 1
            % only run searchlight for the whole brain
            runSearchlight = 3;
        elseif combineHemi == 3
            % run searchlight for left, right hemispheres and both together
            runSearchlight = 1:3;
        end
    end
    
    
    %% conduct searchlight for two hemisphere seprately (and the whole brain)
    for iSL = runSearchlight  % SL = searchlight
        
        hemiInfo = hemis{iSL}; % hemisphere name
        
        % waitbar
        progress = (iSess + iSL/max(runSearchlight)) / (nSess * 2);
        progressMsg = sprintf('Subject: %s.  Hemisphere: %s  \n%0.2f%% finished...', ...
            strrep(subjCode, '_', '\_'), hemiInfo, progress*100);
        waitbar(progress, waitHandle, progressMsg);
        
        %% Surface setting
        % white, pial, surface for this hemisphere
        vtxInflated = vtxCell{iSL};
        faceInflated = faceCell{iSL};
        surfDef = {vtxInflated, faceInflated};
        
        % dataset for this searchlight analysis
        ds_this = dsSurfCell{iSL};
        
        slInfo.subjCode = subjCode;
        slInfo.hemiInfo = hemiInfo;
        slInfo.featureCount = 200;
        
        % run search light analysis
        fs_cosmo_searchlight(slInfo, ds_this, surfDef, classPairs, classifier);
        
    end
    
end

close(waitHandle); % close the waitbar 

end
