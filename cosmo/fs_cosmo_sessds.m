function [ds_sess, condInfo] = fs_cosmo_sessds(sessCode, anaName, runList, ...
    runwise, labelFn, dataFn, parFn, funcPath)
% [ds_sess, condInfo] = fs_cosmo_sessds(sessCode, anaName, [runList='', ...
%    runwise=0, labelFn='', dataFn='beta.nii.gz', parFn='', funcPath])
%
% This function save the functional data on surface (in FreeSurfer) and
% the condition names as a dataset for using in CoSMoMVPA and others.
%
% Inputs:
%    sessCode         <string> session code in funcPath.
%    anaName          <string> analysis name in funcPath.
%    runList          <string> the filename of the run file (e.g.,
%                      run_loc.txt.) [Default is '' and then names of
%                      all run folders will be used.]
%                 OR  <string cell> a list of all the run names. (e.g.,
%                      {'001', '002', '003'....}.
%    runwise          <logical> load the data analyzed combining all runs
%                      [runwise = 0; default]; load the data analyzed for
%                      each run separately [runwise = 1].
%    labelFn          <string> the label name (without path). Its vertex
%                      indices will be used as a mask to the dataset, i.e.,
%                      only the data for vertices in the label sare saved.
%                      [default: '', i.e., keep data for all vertices.]
%    dataFn           <string> the filename of the to-be-read data file.
%                      ['beta.nii.gz' by default]
%    parFn            <string> the filename of the par file. It is empty by
%                      default and will try to find the par file for that run.
%    funcPath         <string> the path to the session folder, 
%                      $FUNCTIONALS_DIR by default.
%
% Outputs:
%    ds_subj          <struct> data set for CoSMoMVPA.
%    condInfo         <struct> condition information for this analysis.
%
% Created by Haiyang Jin (14-Apr-2020)

%% Deal with inputs
if ~exist('funcPath', 'var') || isempty(funcPath)
    funcPath = getenv('FUNCTIONALS_DIR');
end

% generate runFolder based on runwise
if ~exist('runList', 'var') || isempty(runList)
    runList = '';
end

if ischar(runList)
    % read the file if it is char
    runFolder = fs_readrun(runList, sessCode, funcPath);
elseif iscellstr(runList) 
    runFolder = runList;
else
    error('Please make sure ''runList'' is set properly.');
end

if ~exist('runwise', 'var') || isempty(runwise)
    runwise = 0;
end

if ~exist('labelFn', 'var') || isempty(labelFn)
    labelFn = '';
end

if ~exist('dataFn', 'var') || isempty(dataFn)
    dataFn = 'beta.nii.gz';
end

if ~exist('parFn', 'var') || isempty(parFn)
    parFn = '';
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
    
    % load the label file
    tempMask = fs_readlabel(labelFn, fs_subjcode(sessCode, funcPath));
    vtxMask = tempMask(:, 1);
    
    % create mask for the label file
    roiMask = zeros(1, size(ds_all.samples, 2));
    roiMask(vtxMask) = 1;
    
    % apply the mask
    ds_sess = cosmo_slice(ds_all, logical(roiMask), 2);
else
    % keep all data
    ds_sess = ds_all;
end

%% Save the condition information
condInfo = table;
condInfo.Label = {labelFn};
condInfo.nVertices = size(ds_sess.samples, 2);
condInfo.SessCode = {sessCode};

end