function fs_cosmo_sesscrosssl(sessList, classPairs, surfType, template, ...
    combineHemi, classifier, funcPath)
% fs_cosmo_sesscrosssl(sessList, classPairs, [surfType = 'sphere', template = 'fsaverage', ...
%    combineHemi = 0, classifier = '', funcPath])
%
% This function does the searchlight analyses for the whole project
% with CoSMoMVPA. Data were analyzed with FreeSurfer.
%
% Inputs:
%    sessList           <string> or <cell of strings> session code 
%                        (functional subject folder).
%    classPairs         <cell of strings> a PxQ (usually is 2) cell matrix 
%                        for the pairs to be classified. Each row is one 
%                        classfication pair. 
%    surfType           <string> the coordinate file for vertices (
%                        ('sphere', 'inflated', 'white', 'pial').
%    template           <string> 'fsaverage' or 'self'. fsaverage is default.
%    combineHemi        <logical> if the data of two hemispheres will be 
%                        combined (default is no) [0: run searchlight for 
%                        the two hemnispheres separately; 1: run searchlight
%                        anlaysis for the whole brain together; 3: run
%                        analysis for both 0 and 1.
%    classifier         <numeric> or <strings> or <cells> the classifiers 
%                        to be used (only 1).
%    funcPath           <string> the full path to the functional folder.
%
% Output:
%    For each hemispheres, the results will be saved as a *.mgz file saved 
%    at the subject label folder ($SUBJECTS_DIR/subjCode/surf)
%    For the whole brain, the results will be saved as *.gii
%
% Dependency:
%    CoSMoMVPA
%
% Created by Haiyang Jin (24-Nov-2019)

cosmo_warning('once');

if nargin < 3 || isempty(surfType)
    surfType = 'sphere';
end

if nargin < 4 || isempty(template)
    template = '';
end

if nargin < 5 || isempty(combineHemi)
    combineHemi = 0;
end

if nargin < 6
    classifier = '';
end

if nargin < 7 || isempty(funcPath)
    funcPath = getenv('FUNCTIONALS_DIR');
end

%% Preparation
% waitbar
waitHandle = waitbar(0, 'Loading...   0.00% finished');

% information from the project
hemis = {'lh', 'rh'};
nHemi = numel(hemis);
nSess = numel(sessList);

for iSess = 1:nSess
    %% this subject information
    % subjCode in functional folder
    thisSess = sessList{iSess};
    % subjCode in SUBJECTS_DIR
    subjCode = fs_subjcode(thisSess, funcPath);
    
    % waitbar
    progress = iSess / nSess * 1/2;
    progressMsg = sprintf('Loading data for %s (%s).   \n%0.2f%% finished...', ...
        strrep(subjCode, '_', '\_'), template, progress*100);
    waitbar(progress, waitHandle, progressMsg);
    
    % decide the target subject for vertex coordinates based on template
    trgSubj = fs_trgsubj(subjCode, template);
    % load vertex and face coordinates
    [vtxCell, faceCell] = fs_cosmo_surfcoor(trgSubj, surfType, combineHemi);
    
    %% Load functional data (beta.nii.gz)
    % load the beta.nii.gz for both hemispheres separately 
    dsSurfCell = cellfun(@(x) fs_cosmo_subjds(thisSess, x, template, ...
        funcPath, 'main', 0, 1), hemis, 'uni', false);
    
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
        
        featureCount = 200;
        
        % run search light analysis
        fs_cosmo_crosssl(ds_this, classPairs, surfDef, featureCount, ...
            subjCode, hemiInfo, template, classifier);
        
    end  % iSL
    
end  % iSess

% close the waitbar 
close(waitHandle); 

end
