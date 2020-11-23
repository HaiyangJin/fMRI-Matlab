function tfce_cell = fs_cosmo_sesstfce(sessList, anaList, contraList, dataFn, varargin)
% tfce_cell = fs_cosmo_sesstfce(sessList, anaList, contraList, dataFn, varargin)
%
% This function reads the datasets for all sessions (for each condition and
% hemisphere separately) and perform Threshold-free Cluster Enhancement in
% CoSMoMVPA. This function can be applied to the searchlight results
% obtained from CoSMoMVPA or first level results of FreeSurfer. 
%
% Inputs:
%    sessList           <string> the filename of the session file stored in
%                        '$FUNCTIONALS_DIR'.
%                    or <string cell> a list of session codes in funcPath.
%                        ('$FUNCTIONALS_DIR').
%    anaList            <string> or <string cell> one or two analysis name.
%                        If two analysis names are used here, they should
%                        be the same analysis but for different
%                        hemispheres.
%    contraList         <cell of strings> a PxQ (usually is 2) cell matrix
%                        for the pairs to be classified. Each row is one
%                        classfication pair.
%    dataFn             <string> the data filename.
%
% Vararign:
%    .groupfolder       <string> the name of the folder which will save the
%                        outputs (in $SUBJECTS_DIR). Default is 'Group_Results'.
%    .surftype          <string> which surface to be used to perform TFCE.
%                        Default is 'white'. [Probably it is better to use
%                        'intermediate'.]
%    other options defined in cosmo_montecarlo_cluster_stat:
%    .niter=10000 % for publication-quality, use >=1000; 10000 is even better
%    .h0_mean=0.5 % chance level for classification
%    .nproc=10
%
% Output:
%    tfce_cell           <cell> save all the dt_tfce (with z-score).
%    A *.mgz file of the tfce results saved in .groupfolder.
%    A *.mat file of the ds_tfce saved in .groupfolder.
%
% Dependency:
%   CoSMoMVPA.
%
% Created by Haiyang Jin (14-Oct-2020)
%
% See also:
% fs_cvn_print2nd, fs_sl_surfcluster

% waitbar
waitHandle = waitbar(0, 'Loading...   0.00% finished');

defaultOpts = struct();
defaultOpts.groupfolder = 'Group_Results';
defaultOpts.surftype = 'white';
% default options for tfce
defaultOpts.niter=10000; 
defaultOpts.h0_mean=0.5; 
defaultOpts.nproc = 1; 

opts = fs_mergestruct(defaultOpts, varargin{:});

% process inputs
if ischar(sessList)
    sessList = fs_sesslist(sessList);
end
if ischar(anaList); anaList = {anaList}; end
if ischar(contraList); contraList = {contraList}; end

% make folders for saving results
theFolders = fs_fullfile(getenv('FUNCTIONALS_DIR'), opts.groupfolder, ...
    anaList, contraList);
fs_mkdir(theFolders);

nSess = numel(sessList);
nAna = numel(anaList);
nCon = numel(contraList);

tfce_cell = cell(nAna, nCon);

% For each analysis separately
for iAna = 1:nAna
    
    thisAna = anaList{iAna};
    
    % read surface file
    thisHemi = fs_2hemi(thisAna);
    [vertices, faces] = fs_readsurf([thisHemi '.' opts.surftype], 'fsaverage');
    
    for iCon = 1:nCon
        
        % progress bar
        prog1 = ((iAna-1)*nCon + iCon-1);
        prog2 = (nAna * nCon);
        progress = prog1/prog2;
        progressMsg = sprintf('Performing TFCE (%d/%d)...   \n%0.2f%% finished...', ...
            prog1+1, prog2, progress*100);
        waitbar(progress, waitHandle, progressMsg);
        
        thisCon = contraList{iCon};
        
        fprintf(['\nRunning Threshold-free Cluster Enhancement for '...
            '\nAnalysis: %s \nContrast: %s\n'], thisAna, thisCon);
        
        % load data for each contrasts
        dataFilenames = fullfile(getenv('FUNCTIONALS_DIR'), sessList, ...
            'bold', thisAna, thisCon, dataFn);
        data_cell = cellfun(@fs_readfunc, dataFilenames, 'uni', false);
        
        % create the dataset
        ds_this.samples = horzcat(data_cell{:})';
        
        ds_this.sa.chunks = (1:nSess)';
        ds_this.sa.targets = ones(nSess, 1);
        ds_this.sa.labels = sessList;
        
        ds_this.fa.node_indices = 1:size(ds_this.samples, 2);
        ds_this.fa.center_dis = 1:size(ds_this.samples, 2);
        
        ds_this.a.fdim.labels = {'node_indices'};
        ds_this.a.fdim.values = {1:size(ds_this.samples, 2)};
        
        % define neighborhood for each feature
        % neighbors here refer to vertices just next to the center one
        cluster_nbrhood=cosmo_cluster_neighborhood(ds_this,...
            'vertices',vertices,'faces',faces);
        
        %%%% Run Threshold-free Cluster Enhancement
        % Run TFCE-based cluster correction for multiple comparisons.
        % The output has z-scores for each node indicating the probablity to find
        % the same, or higher, TFCE value under the null hypothesis
        fprintf('\nRunning multiple-comparison correction with these options:\n');
        cosmo_disp(opts);
        ds_tfce=cosmo_montecarlo_cluster_stat(ds_this,cluster_nbrhood,opts);
        
        % Save the ds_tfce as .mat and .mgz
        ds_tfce.sa.analysis = thisAna;
        ds_tfce.sa.contrast = thisCon;
        tfcePath = fullfile(getenv('FUNCTIONALS_DIR'), opts.groupfolder, ...
            thisAna, thisCon);
        fs_savemgz('fsaverage', ds_tfce.samples, dataFn, tfcePath, thisHemi);
        save(fullfile(tfcePath, [dataFn, '.mat']), 'ds_tfce');
        
        tfce_cell{iAna, iCon} = ds_tfce;
    end
    
end

% close the waitbar
close(waitHandle);

end