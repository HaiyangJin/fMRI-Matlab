function corTable = cosmo_corr_oddeven(ds, dsInfo, corTypes, coropts)
% corTable = cosmo_corr_oddeven(ds, dsInfo, corTypes, coropts)
%
% This function performs correlation classification with CoSMoMVPA.
%
% Inputs:
%    ds               <struct> dataset obtained from fs_cosmo_subjds.
%    dsInfo           <struct> Extra information to be saved in mvpaTable.
%                      E.g., the condition information obtained from
%                      fs_cosmo_subjds().
%    corTypes        <cell strings> the correlation types to be used (can
%                      be more than 1).
%    coropts         <struct> the possibly other fields that are given to
%                      the correlation. Default is empty struct.
%
% Output:
%    corTable         <table> the correlation result table.
%
% Dependency:
%    CoSMoMVPA
%
% Created by Haiyang Jin (2022-June-13)

if isempty(ds) || isempty(ds.samples)
    corTable = table;
    return;
end

if ~exist('dsInfo', 'var') || isempty(dsInfo)
    dsInfo = '';
end

if ~exist('corTypes', 'var') || isempty(corTypes)
    corTypes = {'Pearson'};
elseif ischar(corTypes)
    corTypes = {corTypes};
end
nCor = numel(corTypes);

% MVPA settings
measure = @cosmo_correlation_measure;  % function handle
measure_args.output = 'raw';
measure_args.post_corr_func = [];
measure_args = fm_mergestruct(measure_args, coropts);

% remove constant features
ds = cosmo_remove_useless_data(ds);

% empty cell for saving data later
corCell = cell(1, nCor);

measure_args.partitions = cosmo_oddeven_partitioner(ds, 'half');

for iCor = 1:nCor

    tmpCor = table;
    measure_args.corr_type = corTypes{iCor};
    ds_cor = measure(ds, measure_args);

    tmpCor.corr_type = corTypes(iCor);
    tmpCor.corr = {cosmo_unflatten(ds_cor, 1)};
    tmpCor.xlabels = {cellfun(@(x) [x, '_even'], ...
        ds.sa.labels(1:sqrt(numel(ds_cor.samples))), 'uni', false)};
    tmpCor.ylabels = {cellfun(@(x) [x, '_odd'], ...
        ds.sa.labels(1:sqrt(numel(ds_cor.samples))), 'uni', false)};

    % save the tmp MVPA table
    corCell(1, iCor) = {tmpCor};
end

% save all tables together
corTable = vertcat(corCell{:});

% combine mvpa data with condition information
nRow = size(corTable, 1);
if ~nRow || isempty(dsInfo)
    corTable = table;
else
    corTable = [repmat(dsInfo, nRow, 1), corTable];
end

end