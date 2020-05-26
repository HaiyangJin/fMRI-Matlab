function [ds_sess, condInfo] = fs_cosmo_sessds(sessCode, anaName, varargin)
% [ds_sess, condInfo] = fs_cosmo_sessds(sessCode, anaName, [runList='', ...
%    runwise=0, labelFn='', dataFn='beta.nii.gz', parFn='', funcPath])
%
% This function save the functional data on surface (in FreeSurfer) and
% the condition names as a dataset for using in CoSMoMVPA and others. A
% similar function is fs_cosmo_subjds (which probably will be deprecated
% later).
%
% Inputs:
%    sessCode       <string> session code in funcPath.
%    anaName        <string> analysis name in funcPath.
%
% Varargin:
%    runlist        <string> the filename of the run file (e.g.,
%                    run_loc.txt.) [Default is '' and then names of all run
%                    folders will be used.]
%               OR  <string cell> a list of all the run names. (e.g.,
%                    {'001', '002', '003'....}.
%    runwise        <logical> load the data analyzed combining all runs
%                    [runwise = 0; default]; load the data analyzed for
%                    each run separately [runwise = 1].
%    labelfn        <string> the label name (without path). Its vertex
%                    indices will be used as a mask to the dataset, i.e.,
%                    only the data for vertices in the label sare saved.
%                    [default: '', i.e., keep data for all vertices.]
%    datafn         <string> the filename of the to-be-read data file.
%                    ['beta.nii.gz' by default]
%    parfn          <string> the filename of the par file. It is empty by
%                    default and will try to find the par file for that run.
%    funcpath       <string> the path to the session folder, 
%                    $FUNCTIONALS_DIR by default.
%
% Outputs:
%    ds_subj          <struct> data set for CoSMoMVPA.
%    condInfo         <struct> condition information for this analysis.
%
% Created by Haiyang Jin (14-Apr-2020)

%% Deal with inputs
defaultOpts = struct(...
    'runlist', '', ...
    'runwise', 0, ... 
    'labelfn', '',... 
    'datafn', 'beta.nii.gz',... 
    'parfn', '', ... 
    'funcpath', getenv('FUNCTIONALS_DIR')...
    );

opts = fs_mergestruct(defaultOpts, varargin);

runList = opts.runlist;
runwise = opts.runwise;
labelFn = opts.labelfn;
dataFn = opts.datafn;
parFn = opts.parfn;
funcPath = opts.funcpath;

if ischar(runList)
    % read the file if it is char
    runFolder = fs_readrun(runList, sessCode, funcPath);
elseif iscell(runList) 
    runFolder = runList;
else
    error('Please make sure ''runList'' is set properly.');
end

%% Read data and condition names
% create the prFolder names if data for each run are read separately
if runwise
    % make the run names ('pr*') (in the analysis folder)
    prFolder = cellfun(@(x) ['pr' x], runFolder, 'uni', false);
else
    prFolder = {''};
    runFolder = runFolder(1);
end

% path to the bold folder
boldPath = fullfile(funcPath, sessCode, 'bold');

% create the full filename to the paradigm file (with path)
parFiles = fullfile(boldPath, runFolder, parFn);
% read all the par files
parCell = cellfun(@fs_readpar, parFiles, 'uni', false);

% create the to-be-read filenames (beta) with path
betaFiles = fullfile(boldPath, anaName, prFolder, dataFn);

% read the data and the corresponding condition names
dsCell = arrayfun(@(x) fs_cosmo_surface(betaFiles{x}, ...
    'targets', parCell{x}.Condition, ...
    'labels', parCell{x}.Label, ...
    'chunks', x), 1:numel(betaFiles), 'uni', false);

% combine data for different runs if necessary
ds_all = cosmo_stack(dsCell,1);

%% Apply the label file as mask if necessary
if ~isempty(labelFn)
    % convert label into mask
    roiMask = fs_label2mask(labelFn, fs_subjcode(sessCode, funcPath), size(ds_all.samples, 2));
    % apply the mask
    ds_sess = cosmo_slice(ds_all, logical(roiMask), 2);
else
    % keep all data
    ds_sess = ds_all;
end

%% Save the condition information
condInfo = table;
condInfo.Label = {labelFn};
condInfo.Analysis = {anaName};
condInfo.nVertices = size(ds_sess.samples, 2);
condInfo.SessCode = {sessCode};

end