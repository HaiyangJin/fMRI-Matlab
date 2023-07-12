function dataTable = prfcf_prf2csv(prf_wc, labels, allvtx)
% extract prf results and save to a CSV file.
%
% prf_wc      <str> wildcard to identify pRF results.
% labels      <cell str> ROIs (vertices).
% allvtx      <boo> whether to output parameters for all verticeis. Default
%              to false. Otherwise will only output parameters for vertices
%              in the labels.

if ~exist('labels', 'var'); labels = []; end 
if ~exist('allvtx', 'var') || isempty(allvtx); allvtx = false; end 

% identify all the matched files
prfFnList = prfcf_listprfs(prf_wc);

% extract parameter for each pRF file
dataCell = cellfun(@(x) prf2csv(x, labels, allvtx), prfFnList, 'uni', false);

% convert to one Table
dataTable = vertcat(dataCell{:});
dataTable.ext = [];

%% Save CSV
writetable(dataTable, sprintf('pRF_parameters_%s.csv', char(datetime('now', 'Format', 'yyyyMMddHHmm'))));

end

function dataTable = prf2csv(prfFn, labels, allvtx)
% extract information from eacg pRF result file.

[prfpath, prfF] = fileparts(prfFn);
info = fp_fn2info(prfFn);

% load result
load(prfFn, 'Srf');

%% labels
if isempty(labels)
    % default label files
    labelFns = cellfun(@(x) sprintf('roi.%s.f13.face-vs-object.%s.label', Srf.Hemisphere, x), ...
        {'ofa', 'ffa1', 'ffa2', 'atl'}, 'uni', false);
else
    [~, labelFns] = cellfun(@fileparts, labels, 'uni', false);
end
labelMats = cellfun(@(x) fs_readlabel(fullfile(prfpath, '..', 'label', x)), ...
    labelFns, 'uni', false);
labelmasks = cellfun(@(x) x(:,1), labelMats, 'uni', false);

labelmask = vertcat(labelmasks{:});
if length(labelmask) > length(unique(labelmask))
    warning('There are overlaps between ROIs.');
end
if allvtx
    labelmask = Srf.Roi; % output all vertices
else
    labelmask = unique(labelmask(:));
end

labelCol = cell(size(labelmask));
% roiCol = cell(size(labelmask));
for ilabel = 1:length(labelFns)
    labelCol(ismember(labelmask, labelmasks{ilabel}(:,1))) = labelFns(ilabel);
end

% expand Srf
oldpath = pwd;
cd(prfpath);
Srf = samsrf_expand_srf(Srf);
cd(oldpath);
% load data
dataTable = array2table(Srf.Data(:, labelmask)', 'VariableNames', Srf.Values);

% add general information
info.hemi = info.custom1;
info = rmfield(info, 'custom1');
infoTone = struct2table(info);
% foce all columns to cell
infoTone = cell2table(table2cell(infoTone), 'VariableNames', fieldnames(info));
infoTone.analysis = {prfF};
infoT = repmat(infoTone, size(dataTable,1), 1);
infoT.label = labelCol;

% combine to one table
dataTable = horzcat(infoT, dataTable);

end
