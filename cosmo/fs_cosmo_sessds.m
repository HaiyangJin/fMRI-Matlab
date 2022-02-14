function [ds_sess, dsInfo] = fs_cosmo_sessds(sessCode, anaName, varargin)
% [ds_sess, condInfo] = fs_cosmo_sessds(sessCode, anaName, varargin)
%
% This function save the functional data on surface (in FreeSurfer) and
% the condition names as a dataset for using in CoSMoMVPA and others. A
% similar function is fs_cosmo_subjds (which probably will be deprecated
% later).
%
% Inputs:
%    sessCode       <str> session code in $FUNCTIONALS_DIR.
%    anaName        <str> analysis name in $FUNCTIONALS_DIR.
%
% Varargin:
%    runwise        <boo> load the data analyzed combining all runs
%                    [runwise = 0; default]; load the data analyzed for
%                    each run separately [runwise = 1] (this applies only 
%                    when argument '-run-wise' is used for 'selxavg3-sess'. 
%    labelfn        <str> the label name (without path). Its vertex
%                    indices will be used as a mask to the dataset, i.e.,
%                    only the data for vertices in the label sare saved.
%                    [default: '', i.e., keep data for all vertices.]
%    datafn         <str> the filename of the to-be-read data file.
%                    ['beta.nii.gz' by default]
%    ispct          <boo> use whether the raw 'beta.nii.gz' or signal
%                    percentage change. Default is 0.
%    parfn          <str> the filename of the par file. It is empty by
%                    default and will try to find the par file for that run.
%                    [to be deprecated; this information is read from
%                    'analysis.info'.]
%    runinfo        <str> the filename of the run file (e.g.,
%                    run_loc.txt.) [Default is '' and then names of all run
%                    folders will be used.]
%               OR  <cell str> a list of all the run names. (e.g.,
%                    {'001', '002', '003'....}. 
%                    [to be deprecated; this information is read from
%                    'analysis.info'.]
%
% Outputs:
%    ds_subj        <struct> data set for CoSMoMVPA.
%    dsInfo         <struct> condition information for this analysis.
%     .Label        <str> the label name.
%     .Analysis     <str> analysis name.
%     .nVertices    <int> number of vertices in this label.
%     .SessCode     <str> this session code.
%
% Created by Haiyang Jin (14-Apr-2020)
%
% See also:
% fs_cosmo_multids

%% Deal with inputs

if nargin < 1
    fprintf('Usage: [ds_sess, dsInfo] = fs_cosmo_sessds(sessCode, anaName, varargin);\n');
    return;
end

defaultOpts = struct(...
    'runwise', 0, ... 
    'labelfn', '',... 
    'datafn', 'beta.nii.gz',... 
    'ispct', '', ... % 0 default for fs_cosmo_surface
    'parfn', '', ... % to be deprecated
    'runinfo', '' ... % to be deprecated
    );

opts = fm_mergestruct(defaultOpts, varargin{:});

% skip if the label file (if not empty) is not avaiable 
labelFn = opts.labelfn;
if ~isempty(labelFn) && isempty(fs_readlabel(labelFn, fs_subjcode(sessCode)))
    ds_sess = [];
    dsInfo = table;
    return;
end

anaInfo = fs_readanainfo(anaName, sessCode);
if isempty(opts.runinfo)
    opts.runinfo = anaInfo.runlistfile;
end
runList = fs_runlist(sessCode, opts.runinfo);

if isempty(opts.parfn)
    opts.parfn = anaInfo.parname;
end

%% Read data and condition names
% create the prFolder names if data for each run are read separately
if opts.runwise
    % make the run names ('pr*') (in the analysis folder)
    prList = cellfun(@(x) ['pr' x], runList, 'uni', false);
else
    prList = {''};
    runList = runList(1);
end

% path to the bold folder
boldPath = fullfile(getenv('FUNCTIONALS_DIR'), sessCode, 'bold');

% create the full filename to the paradigm file (with path)
parFiles = fullfile(boldPath, runList, opts.parfn);
% read all the par files
parCell = cellfun(@fm_readpar, parFiles, 'uni', false);

% create the to-be-read filenames (beta) with path
dataFiles = fullfile(boldPath, anaName, prList, opts.datafn);

% read the data and the corresponding condition names
dsCell = arrayfun(@(x) fs_cosmo_surface(dataFiles{x}, ...
    'targets', parCell{x}.Condition, ...
    'labels', parCell{x}.Label, ...
    'pct', opts.ispct, ...
    'chunks', x), 1:numel(dataFiles), 'uni', false);

% combine data for different runs if necessary
ds_all = cosmo_stack(dsCell,1);

%% Apply the label file as mask if necessary
if ~isempty(labelFn)
    % convert label into mask
    roiMask = fs_label2mask(labelFn, fs_subjcode(sessCode), size(ds_all.samples, 2));
    % apply the mask
    ds_sess = cosmo_slice(ds_all, logical(roiMask), 2);
else
    % keep all data
    ds_sess = ds_all;
end

%% Save the condition information
dsInfo = table;
dsInfo.Label = {labelFn};
dsInfo.Analysis = {anaName};
dsInfo.nVertices = size(ds_sess.samples, 2);
dsInfo.SessCode = {sessCode};

end