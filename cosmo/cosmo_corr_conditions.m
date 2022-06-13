function corTable = cosmo_corr_conditions(ds, dsInfo, corTypes, split_by)
% corTable = cosmo_corr_oddeven(ds, dsInfo, corTypes, split_by)
%
% This function performs correlation classification with CoSMoMVPA.
%
% Inputs:
%    ds               <struct> dataset obtained from fs_cosmo_subjds.
%    dsInfo           <struct> Extra information to be saved in mvpaTable.
%                      E.g., the condition information obtained from
%                      fs_cosmo_subjds().
%    corTypes         <cell str> the correlation types to be used (can
%                      be more than 1).
%    split_by         <cell str> fields used to get average across samples,
%                      more see cosmo_average_samples(). Default is 
%                      {'targets','chunks'}.
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

if ~exist('split_by', 'var') || isempty(split_by)
    split_by = {'targets','chunks'};
end
ds = cosmo_average_samples(ds, 'split_by', split_by);

% remove constant features
ds = cosmo_remove_useless_data(ds);

% empty cell for saving data later
corCell = cell(1, nCor);

for iCor = 1:nCor

    tmpCor = table;
    corr_type = corTypes(iCor);

    tmpCor.corr_type = corr_type;
    tmpCor.corr = {cosmo_corr(ds.samples', ds.samples', corr_type{1})};

    condnames = arrayfun(@(x) sprintf('%s_%d', ds.sa.labels{x}, ...
        ds.sa.chunks(x)), 1:numel(ds.sa.chunks), 'uni', false);
    tmpCor.xlabels = {condnames};
    tmpCor.ylabels = {condnames};

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