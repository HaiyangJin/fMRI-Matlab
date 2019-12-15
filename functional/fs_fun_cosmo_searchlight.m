function fs_fun_cosmo_searchlight(projStr, file_surfcoor, combineHemi, classPairs, classifier)
% This function does the searchlight analyses for the faceword project
% with CoSMoMVPA. Data were analyzed with FreeSurfer.
%
% Inputs:
%    subjCode_bold      the name of subject's bold folder
%    expCode            experiment code (1 or 2)
%    file_surfcoor      the coordinate file for vertices ('inflated',
%                       'white', 'pial')
%    combineHemi        if the data of two hemispheres will be combined
%                       (default is no) [0: run searchlight for the two
%                       hemnispheres separately; 1: run searchlight
%                       anlaysis for the whole brain together; 3: run
%                       analysis for both 0 and 1.
%    classifier         classifier function handle
% Output:
%    For each hemispheres, the results will be saved as a label file saved
%    at the subject label folder ($SUBJECTS_DIR/subjCode/label)
%    For the whole brain, the results will be saved as *.gii
%
% Created by Haiyang Jin (24/11/2019)
% Updated by Haiyang Jin (15/12/2019)

cosmo_warning('once');

if nargin < 3 || isempty(file_surfcoor)
    file_surfcoor = 'inflated';
end
if nargin < 4 || isempty(combineHemi)
    combineHemi = 0;
end
if nargin < 5
    classifier = '';
end

%% Preparation
% information from the project
nHemi = projStr.nHemi;
fMRIPath = projStr.fMRI;

subjList = projStr.subjList;
nSubj = projStr.nSubj;

for iSubj = 1:nSubj
    %% this subject information
    % subjCode in fMRI folder
    subjCode_bold = subjList{iSubj};
    % subjCode in SUBJECTS_DIR
    subjCode = fs_subjcode(subjCode_bold, fMRIPath);
    
    hemis = projStr.hemis;
    
    % load vertex and face coordinates
    [vtxCell, faceCell] = fs_cosmo_surfcoor(subjCode, file_surfcoor, combineHemi);
    
    
    %% Load functional data (beta.nii.gz)
    % load the beta.nii.gz for both hemispheres separately
    [~, ds_surf_cell] = cellfun(@(x) fs_fun_uni_cosmo_ds(projStr, x, subjCode_bold, ...
        '', 'main', 0, 1), hemis, 'UniformOutput', false);
    
    % combine the surface data for the whole brain if needed
    if ~combineHemi
        runSearchlight = 1:nHemi;
    else
        ds_surf_cell = [ds_surf_cell, fs_cosmo_combinesurface(ds_surf_cell)]; %#ok<AGROW>
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
        
        hemi_info = hemis{iSL}; % hemisphere name
        
        %% Surface setting
        % white, pial, surface for this hemisphere
        v_inf = vtxCell{iSL};
        f_inf = faceCell{iSL};
        surf_def = {v_inf, f_inf};
        
        % dataset for this searchlight analysis
        ds_this = ds_surf_cell{iSL};
        
        % run search light analysis
        fs_cosmo_searchlight(subjCode, ds_this, surf_def, hemi_info, classPairs, classifier);
        
    end
    
end

end
