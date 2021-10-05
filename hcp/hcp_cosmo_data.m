function ds = hcp_cosmo_data(subjCode, runinfo, funcstr, islevel1)
% ds = hcp_cosmo_data(subjCode, runinfo, funcstr, islevel1)
%
% Read the functional results on surface from FEAT in HCP. 
%
% Inputs:
%    subjCode      <string> subject code.
%    runinfo       <cell string> list of run folders.
%               or <string> string pattern (wildcard) to match run folders.
%    funcstr       <string> string pattern (wildcard) to match the 
%                   functional filename. Default is 'pe%d.dtseries.nii', 
%                   i.e., the parameter estimation.
%    islevel1      <logical> whether collect data for level1 analysis
%                   results in HCP (FSL). Default is 1.
%
% % Example 1: load condition data for each run separately (level1)
% ds = hcp_cosmo_data(subjCode, '*FUNC_0*');
%
% % Example 2: load contrast data for each run separately (level1)
% ds = hcp_cosmo_data(subjCode, '*FUNC_0*', 'cope*.dtseries.nii');
% ds = hcp_cosmo_data(subjCode, '*FUNC_0*', 'cope%d.dtseries.nii');
% ds = hcp_cosmo_data(subjCode, '*FUNC_0*', 'tstat*.dtseries.nii');
%
% % Example 3: load contrast data across runs (level2)
% ds = hcp_cosmo_data(subjCode, '*Main*', '*_cope_hp200_s2.dscalar.nii', 0);
%
% % Example 4: use list of run folder names instead of string patterns
% ds = hcp_cosmo_data(subjCode, {'tfMRI_FUNC_01_PA', 'tfMRI_FUNC_02_PA'});
%
% Created by Haiyang Jin (2021-09-28)

% setup
if ~exist('runinfo', 'var') || isempty(runinfo)
    error('Please set "runinfo" as a list of run folder names.'); 
end

if ~exist('funcstr', 'var') || isempty(funcstr)
    funcstr = 'pe%d.dtseries.nii'; % parameter estimation
end

if ~exist('islevel1', 'var') || isempty(islevel1)
    islevel1 = 1;
end

% get the functional data directory
funcdir = hcp_funcdir(subjCode);

% get the run list
if ischar(runinfo)
    rundir = dir(fullfile(funcdir, runinfo));
    runlist = {rundir.name};
elseif iscell(runinfo)
    runlist = runinfo;
end
nRun = length(runlist);
dsCell = cell(nRun, 1);

% read dt for each folder (or run) separately
for iRun = 1:nRun

    runfolder = runlist{iRun};

    % find the folder name ending with *.feat
    featdir = dir(fullfile(funcdir, runfolder, '*.feat'));
    if islevel1
        featfn = fullfile(featdir.name, 'GrayordinatesStats');
    else
        featfn = featdir.name;
    end

    % get condition (or contrast) names
    if startsWith(funcstr, 'pe')
        % read condition information for parameter estimation
        condir = dir(fullfile(funcdir, runfolder, 'par2ev', '*.txt'));
        conList = sort(cellfun(@(x) erase(x, ".txt"), {condir.name}, 'uni', false));

    elseif startsWith(funcstr, {'cope', 'tstat', 'zstat', 'varcope'})
        % read contrast information (level1)
        condir = dir(fullfile(funcdir, runfolder, featdir.name, 'design.con'));
        conList = hcp_readcon(fullfile(condir.folder, condir.name)); % contrast list

    else
        % read contrast information (across runs; level2)
        conList = fm_readtext(fullfile(funcdir, runfolder, featdir.name, 'Contrasts.txt'));

    end
    nCon = length(conList); % condition list

    % read samples
    if contains(funcstr, '%d')
        % only read the fisrt nCon files
        datalist = arrayfun(@(x) sprintf(funcstr, x), 1:nCon, 'uni', false);
        tmp_data = cellfun(@hcp_readfunc, fullfile(funcdir, runfolder, featfn, datalist), 'uni', false);
    else
        % read all matching files
        datadir = dir(fullfile(funcdir, runfolder, featfn, funcstr));
        tmp_data = cellfun(@hcp_readfunc, fullfile({datadir.folder}, {datadir.name}), 'uni', false);
    end

    % set samples
    tmp_ds = struct;
    tmp_ds.samples = horzcat(tmp_data{:})';  % conditions * vertices (gray ordinates)

    % set targets and chunks
    tmp_ds=set_vec_sa(tmp_ds, 'targets', 1:nCon);
    tmp_ds=set_vec_sa(tmp_ds, 'labels', conList);
    tmp_ds=set_vec_sa(tmp_ds, 'chunks', iRun);
    tmp_ds=set_vec_sa(tmp_ds, 'runname', {runfolder});

    dsCell{iRun, 1} = tmp_ds;

end

% combine ds across runs
ds = cosmo_stack(dsCell,1);

% .fa
ds.fa.node_indices = 1:size(ds.samples, 2);

% .a
ds.a.fdim.labels = {'node_indices'};
ds.a.fdim.values = {1:size(ds.samples,2)};

% check consistency
cosmo_check_dataset(ds,'surface');

end

function ds=set_vec_sa(ds, label, values)
% set the parameters
if isempty(values)
    return;
end
if numel(values)==1
    nsamples=size(ds.samples,1);
    values=repmat(values,nsamples,1);
end
ds.sa.(label)=values(:);
end