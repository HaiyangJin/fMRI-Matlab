function dtTable = fs_cosmo_readdata(sessList, anaList, varargin)
% dtTable = fs_cosmo_readdata(sessList, anaList, varargin)
%
% This function reads the functional data for each session (masked by
% labels if they are not empty).
%
% Inputs:
%    sessList       <cell str> a list of session codes.
%    anaList        <cell str> a list of analysis names.
%
% Optional (varargin):
%    'labellist'    <cell str> a list of label names. Default is '' and
%                    all vertex values will be saved.
%    'labelInfo'    <boo> 0 [default]: do not add label information in
%                    dtTable. 1: add label information to dtTable.
%    'calmean'      <boo> 1 [default]: calculate and output the mean of
%                    all vertex values. 0: output the vertex values
%                    directly (without calculating the means).
%    <options for fs_cosmo_sessds.m> e.g.:
%    'runinfo'      <str> the filename of the run file (e.g.,
%                    run_loc.txt.) [Default is '' and then names of all run
%                    folders will be used.]
%                OR <cell str> a list of all the run names. (e.g.,
%                    {'001', '002', '003'....}.
%    'runwise'      <boo> 0 [default]: load the data analyzed by
%                    combining all runs; 1: load the data analyzed for
%                    each run separately.

%    'extraopt'     <cell> extra options for .
%
% Output:
%    dtTable        <table> a table of all the data.
%
% Created by Haiyang Jin (25-May-2020)

%% Deal with inputs
defaultOpts = struct(...
    'labellist', '', ...
    'runlist', '', ...
    'runwise', 0, ...
    'labelinfo', 0, ...
    'calmean', 1, ...
    'extraopt', {{}} ...
    );

opts = fm_mergestruct(defaultOpts, varargin);

labelList = opts.labellist;
opts.labellist = [];
labelInfo = opts.labelinfo;
opts.labelInfo = [];
calMean = opts.calmean;
opts.calmean = [];

if ischar(labelList)
    labelList = {labelList};
end
nLabel = numel(labelList);

%% Read data for all subjects (all vertices)
% all combinations between sessions and analyses
[tempSess, tempAna] = ndgrid(sessList, anaList);
sess = tempSess(:);
ana = tempAna(:);

% load dataset
[ds_cell, condCell] = cellfun(@(x, y) fs_cosmo_sessds(x, y, opts), ...
    sess, ana, 'uni', false);

% save the condition information as a table
condTable = vertcat(condCell{:});
condTable.Analysis = ana;

% empty cell for saving data table
uniCell = cell(nLabel, 1);

for iLabel = 1:nLabel
    
    % this label and hemi
    thisLabel = labelList{iLabel};
    thisHemi = fm_2hemi(thisLabel);
    
    % only keep data and condition information matching thisHemi
    matchHemi = endsWith(condTable.Analysis, thisHemi)';
    theCondTable = condTable(matchHemi, :);
    the_ds = ds_cell(matchHemi, :);
    
    % create roi masks with the labels
    roiMask = cellfun(@(x, y) fs_label2mask(thisLabel, x, numel(y.samples))', ...
        fs_subjcode(theCondTable.SessCode), the_ds, 'uni', false);
    
    % apply roi masks and compute the mean
    dataTCell = cellfun(@(x, y) ds2table(x, y, calMean, runwise), the_ds, roiMask, 'uni', false);
    
    % repeat condition information to match dataTCell
    condTCell = arrayfun(@(x) repmat(theCondTable(x, :), size(dataTCell{x, 1}, 1), 1), 1:sum(matchHemi), 'uni', false)';
    
    % combine data and condition information
    tempTable = horzcat(vertcat(condTCell{:}), vertcat(dataTCell{:}));
    % add label names
    tempTable.Label = repmat({thisLabel}, size(tempTable, 1), 1);
    
    % save the data for this label
    uniCell{iLabel, 1} = tempTable;
    
end

% save the data as table
dtTable = vertcat(uniCell{:});

% add label informationt output if needed
if labelInfo
    labelInfoT = fs_labelinfo(dtTable.Label, fs_subjcode(dtTable.SessCode), ...
        'isndgrid', 0, 'saveall', 1);
    dtTable = [labelInfoT, dtTable];
end

end

%% Covnert cosmo ds to table
function outT = ds2table(ds, roi, calMean, runwise)
% read ds samples with roi
Response = ds.samples(:, roi);

% calculate the mean if needed
if calMean
    Response = mean(Response, 2);
else
    Response = num2cell(Response, 2);
end

% save the condition names
Condition = ds.sa.labels;

% save chunk and target if needed
if runwise
    Chunk = ds.sa.chunks;
    Target = ds.sa.targets;
    outT = table(Chunk, Condition, Target, Response);
else
    outT = table(Condition, Response);
end

end