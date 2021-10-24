function contraPairs = fs_cosmo_sesssl(sessList, anaList, classPairs, varargin)
% contraPairs = fs_cosmo_sesssl(sessList, anaList, classPairs, varargin)
%
% This function performs the searchlight analyses for the whole project
% with CoSMoMVPA. Data were analyzed with FreeSurfer.
%
% Inputs:
%    sessList           <str> or <cell str> session codes in funcPath.
%                        (functional subject folder).
%    anaList            <str> or <cell str> one or two analysis name.
%                        If two analysis names are used here, they should
%                        be the same analysis but for different
%                        hemispheres. Within the analysis, the GLM should
%                        be performed for each run separately (i.e., use
%                        -run-wise for selxavg3-sess in FreeSurfer).
%    classPairs         <cell str> a PxQ (usually is 2) cell matrix
%                        for the pairs to be classified. Each row is one
%                        classfication pair.
%
% Varargin:
%    'area'             <num> maximum area for neighbors if it is not
%                        empty. Default is [] (it will use 100mm^2).
%    'runlist'          <str> the filename of the run file (e.g.,
%                        run_loc.txt.) [Default is '' and then names of
%                        all run folders will be used.]
%                   OR  <cell str> a list of all the run names. (e.g.,
%                        {'001', '002', '003'....}.
%    'nbrstr'           <str> custom strings to be added to the
%                        searchlight analysis folders. Default is ''.
%    'datafn'           <str> the filename of the to-be-read data file.
%                        Default is '' and 'beta.nii.gz' will be load.
%    'ispct'            <boo> use whether the raw 'beta.nii.gz' or
%                        signal percentage change. Default is 0.
%    'surftype'         <str> the coordinate file for vertices (e.g.,
%                        ('sphere', 'inflated', 'white', 'pial'). Default
%                        is 'sphere'.
%    'bothhemi'         <boo> whether the data of two hemispheres will
%                        be combined (default is no [0]) [0: run searchlight
%                        for the two hemnispheres separately; 1: run
%                        searchlight anlaysis only for the whole brain
%                        together; 3: run analysis for both 0 and 1.
%    'funcpath'         <str> the full path to the functional folder.
%                        Default is $FUNCTIONALS_DIR.
%    'cvslopts'         <cell> varargins for fs_cosmo_cvsl.m.
%
% Output:
%    contraPairs        <cell str> the contrast folders to save the
%                        searchlight results (within the analysis folder) .
%    For each hemispheres, the results will be saved as a *.mgz file (in
%    the pseudo-analysis folder within the session folder).
%    For the whole brain, the results will be saved as *.gii.
%
% % Example 1: Perform searhlight to decode 'con1' vs. 'con2' for session 
% % 'sess01' and analaysis 'main_sm0_E1_fsaverage.lh' (with the default 
% % 100mm^2 area). 
% contraPairs = fs_cosmo_sesssl({'sess01'}, {'main_sm0_E1_fsaverage.lh'}, {'con1', 'con2'});
%
% % Example 2: Perform searchlight with area of 150mm^2.
% contraPairs = fs_cosmo_sesssl({'sess01'}, {'main_sm0_E1_fsaverage.lh'}, ...
%     {'con1', 'con2'}, 'area', 150);
%
% Dependency:
%    CoSMoMVPA
%
% Created by Haiyang Jin (24-Nov-2019)
%
% See also:
% fs_cosmo_cvdecode, fs_cosmo_sesstfce

cosmo_warning('once');

%% Deal with inputs

% default options
defaultOpt=struct(...
    'area', [], ...
    'runlist', '', ... % names of all runs in the bold path will be used.
    'nbrstr', '', ...
    'datafn', 'beta.nii.gz', ...  % beta.nii.gz will be used.
    'ispct', 0, ...
    'surftype', 'white', ... % the surface layer
    'bothhemi', 0, ...  % do not run both hemispheres
    'funcpath', getenv('FUNCTIONALS_DIR'), ...
    'cvslopts', {{}} ...
    );

% parse options
opt=fm_mergestruct(defaultOpt, varargin{:});

runList = opt.runlist;
dataFn = opt.datafn;
surfType = opt.surftype;
bothHemi = opt.bothhemi;
funcPath = opt.funcpath;
cvslOpts = fm_mergestruct('funcpath', opt.funcpath, opt.cvslopts{:});
cvslOpts.area = opt.area;
if ~isempty(opt.nbrstr) && ~endsWith(opt.nbrstr, '_')
    opt.nbrstr = [opt.nbrstr, '_'];
end
cvslOpts.nbrstr = [opt.nbrstr, surfType];

if ischar(sessList); sessList = {sessList}; end
if ischar(anaList)
    anaList = {anaList};
elseif numel(anaList) > 2
    error('Please do not put more than two analyses in ''anaList''.');
elseif size(anaList, 1) == 2
    % make anaList to one row
    anaList = anaList';
end

% sanity check
hemis = {'lh', 'rh'};
if bothHemi
    assert(numel(anaList)==2, ['Please include analyses for both '...
        'hemispehres for searchlight performing on the whole brain.']);
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
    progress = (iSess-1) / nSess;
    progressMsg = sprintf('Loading data for %s (%s).   \n%0.2f%% finished...', ...
        strrep(thisSess, '_', '\_'), template, progress*100);
    waitbar(progress, waitHandle, progressMsg);

    %%%%%% load the beta.nii.gz for both hemispheres separately %%%%%
    dsSurfCell = cellfun(@(x) fs_cosmo_sessds(thisSess, x, ...
        'runlist', runList, 'runwise', 1, 'datafn', dataFn, 'ispct', opt.ispct), ...
        anaList, 'uni', false);

    %%%%%% load vertex and faces information %%%%%
    % decide the target subject for vertex coordinates based on template
    trgSubj = fs_trgsubj(fs_subjcode(thisSess, funcPath), template);
    % load vertex and face coordinates
    [vtxCell, faceCell] = fs_cosmo_surfcoor(trgSubj, surfType, bothHemi);

    % combine the surface data for the whole brain if needed
    if bothHemi && ~strcmp(surfType, 'sphere')
        dsSurfCell = [dsSurfCell, cosmo_combinesurf(dsSurfCell)]; %#ok<AGROW>
        anaList = horzcat(anaList, 'lhrh'); %#ok<AGROW>
        temp = 3:-1:1;
        runHemis = sort(temp(1:bothHemi));
    else
        runHemis = 1:numel(dsSurfCell);
    end

    %% conduct searchlight for two hemisphere seprately (and the whole brain)
    for iHemi = runHemis

        % waitbar
        progress = ((iSess-1)*numel(runHemis) + (iHemi-1))/(nSess * numel(runHemis));
        progressMsg = sprintf('Subject: %s.  Analysis: %s  \n%0.2f%% finished...', ...
            strrep(thisSess, '_', '\_'), strrep(anaList{iHemi}, '_', '\_'), progress*100);
        waitbar(progress, waitHandle, progressMsg);

        %% Surface setting
        % white, pial, surface for this hemisphere
        vtxArray = vtxCell{iHemi};
        faceArray = faceCell{iHemi};
        surfDef = {vtxArray, faceArray};

        % load areas if necessary
        if ~isempty(opt.area) && iHemi<3
            try
                % use the surface definition to calculate area
                cvslOpts.areas = surfing_surfacearea(vtxArray, faceArray);
            catch
                tmpareafile = [hemis{iHemi} '.area'];
                warning('%s is used as "suring_surfacearea" failed.', tmpareafile);
                cvslOpts.areas = fs_readcurv(tmpareafile,trgSubj);
            end
        end

        % dataset for this searchlight analysis
        ds_this = dsSurfCell{iHemi};

        % run search light analysis
        [~, contraPairs] = fs_cosmo_cvsl(ds_this, classPairs, surfDef, thisSess, anaList{iHemi}, cvslOpts);

    end  % iSL

end  % iSess

% create the contrast folder names
% contraPairs = cellfun(@(x,y) sprintf('%s-vs-%s', x, y), ...
%     classPairs(:, 1), classPairs(:, 2), 'uni', false);

% close the waitbar
close(waitHandle);

end
