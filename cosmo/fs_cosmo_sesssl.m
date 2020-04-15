function fs_cosmo_sesssl(sessList, anaList, classPairs, runList, ...
     outPrefix, dataFn, surfType, bothHemi, classifier, funcPath)
% fs_cosmo_sesssl(sessList, anaList, classPairs, runList, ...
%     outPrefix, dataFn, surfType, bothHemi, classifier, funcPath)
%
% This function does the searchlight analyses for the whole project
% with CoSMoMVPA. Data were analyzed with FreeSurfer.
%
% Inputs:
%    sessList           <string> or <string cell> session codes in funcPath.
%                        (functional subject folder).
%    anaList            <string> or <string cell> one or two analysis name.
%                        If two analysis names are used here, they should 
%                        be the same analysis but for different
%                        hemispheres.
%    classPairs         <cell of strings> a PxQ (usually is 2) cell matrix
%                        for the pairs to be classified. Each row is one
%                        classfication pair.
%    runList            <string> the filename of the run file (e.g.,
%                        run_loc.txt.) [Default is '' and then names of
%                        all run folders will be used.]
%                   OR  <string cell> a list of all the run names. (e.g.,
%                        {'001', '002', '003'....}.
%    outPrefix          <string> strings to be added at the beginning of 
%                        the ouput folder (the pseudo-analysis folder).
%                        Default is 'sl'.
%    dataFn             <string> the filename of the to-be-read data file.
%                        Default is '' and 'beta.nii.gz' will be load.
%    surfType           <string> the coordinate file for vertices (
%                        ('sphere', 'inflated', 'white', 'pial'). Default
%                        is 'sphere'.
%    bothHemi           <logical> whether the data of two hemispheres will 
%                        be combined (default is no [0]) [0: run searchlight 
%                        for the two hemnispheres separately; 1: run 
%                        searchlight anlaysis onlyh for the whole brain 
%                        together; 3: run analysis for both 0 and 1.
%    classifier         <numeric> or <strings> or <cells> the classifiers
%                        to be used (only 1).
%    funcPath           <string> the full path to the functional folder.
%                        Default is $FUNCTIONALS_DIR.
%
% Output:
%    For each hemispheres, the results will be saved as a *.mgz file (in
%    the pseudo-analysis folder within the session folder).
%    For the whole brain, the results will be saved as *.gii.
%
% Dependency:
%    CoSMoMVPA
%
% Created by Haiyang Jin (24-Nov-2019)

cosmo_warning('once');

%% Deal with inputs

if ischar(sessList); sessList = {sessList}; end
if ischar(anaList)
    anaList = {anaList}; 
elseif numel(anaList) > 2
    error('Please do not put more than two analysis names in ''anaList''.');
elseif size(anaList, 1) == 2
    % make anaList to one row
    anaList = anaList';
end

if ~exist('runList', 'var') || isempty(runList)
    runList = '';  % names of all runs in the bold path will be used.
end

if ~exist('outPrefix', 'var') || isempty(outPrefix)
    outPrefix = 'sl';
end

if ~exist('dataFn', 'var') || isempty(dataFn)
    dataFn = '';  % beta.nii.gz will be used.
end

if ~exist('surfType', 'var') || isempty(surfType)
    surfType = 'sphere';
end

if ~exist('bothHemi', 'var') || isempty(bothHemi)
    bothHemi = 0;  % do not combine both hemisphere
end

if ~exist('classifier', 'var')
    classifier = '';  % libsvm will be used.
end

if ~exist('funcPath', 'var') || isempty(funcPath)
    funcPath = getenv('FUNCTIONALS_DIR');
end

%% Preparation
% waitbar
waitHandle = waitbar(0, 'Loading...   0.00% finished');

% identify the template from the analysis list
template = fs_2template(anaList, '', 'fsaverage');

if ~ischar(template)
    template = unique(template);
    assert(numel(template) == 1, 'Please make sure the same template is used.');
    template = template{1};
end

nSess = numel(sessList);
for iSess = 1:nSess
    %% this session information
    % sessCode in functional folder
    thisSess = sessList{iSess};
    
    % waitbar
    progress = iSess / nSess * 1/2;
    progressMsg = sprintf('Loading data for %s (%s).   \n%0.2f%% finished...', ...
        strrep(thisSess, '_', '\_'), template, progress*100);
    waitbar(progress, waitHandle, progressMsg);
    
    %%%%%% load the beta.nii.gz for both hemispheres separately %%%%%
    dsSurfCell = cellfun(@(x) fs_cosmo_sessds(thisSess, x, runList, 1, '', dataFn), ...
        anaList, 'uni', false);
    
    %%%%%% load vertex and faces information %%%%%
    % decide the target subject for vertex coordinates based on template
    trgSubj = fs_trgsubj(fs_subjcode(thisSess, funcPath), template);
    % load vertex and face coordinates
    [vtxCell, faceCell] = fs_cosmo_surfcoor(trgSubj, surfType, bothHemi);
    
    % combine the surface data for the whole brain if needed
    if bothHemi && ~strcmp(surfType, 'sphere')
        dsSurfCell = [dsSurfCell, cosmo_combinesurf(dsSurfCell)]; %#ok<AGROW>
        anaList = horzcat(anaList, 'both'); %#ok<AGROW>
        temp = 3:-1:1;
        runHemis = sort(temp(1:bothHemi));
    else
        runHemis = 1:numel(dsSurfCell);
    end
    
    %% conduct searchlight for two hemisphere seprately (and the whole brain)
    for iHemi = runHemis  
                
        % waitbar
        progress = (iSess + iHemi-1/max(runHemis)) / (nSess * 2);
        progressMsg = sprintf('Subject: %s.  Analysis: %s  \n%0.2f%% finished...', ...
            strrep(thisSess, '_', '\_'), strrep(anaList{iHemi}, '_', '\_'), progress*100);
        waitbar(progress, waitHandle, progressMsg);
        
        %% Surface setting
        % white, pial, surface for this hemisphere
        vtxArray = vtxCell{iHemi};
        faceArray = faceCell{iHemi};
        surfDef = {vtxArray, faceArray};
        
        % dataset for this searchlight analysis
        ds_this = dsSurfCell{iHemi};
        featureCount = 200;
        
        % run search light analysis
        fs_cosmo_crosssl(ds_this, classPairs, surfDef, featureCount, ...
            thisSess, anaList{iHemi}, outPrefix, funcPath, classifier);
        
    end  % iSL
    
end  % iSess

% close the waitbar
close(waitHandle);

end
