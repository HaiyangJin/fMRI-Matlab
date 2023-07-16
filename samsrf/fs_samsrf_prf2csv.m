function dataTable = fs_samsrf_prf2csv(prf_wc, labels, allvtx)
% dataTable = fs_samsrf_prf2csv(prf_wc, labels, allvtx)
%
% Extract prf results and save to a CSV file.
%
% Inputs:
%    prfFnList        <cell str> a list of Srf files to be displayed.
%    labels           <cell str> labels (with path if they are not in the 
%                      Srf/ folder) to be displayed. Default to some label
%                      files, e.g., roi.lh.f13.face-vs-object.ofa.label.
%                      If you do not know what this label file refers to,
%                      you probably should set your own lable names. But
%                      the label names have to include the hemisphere
%                      information (e.g., 'lh'), which will be upated to
%                      match the Srf file automatically.
%    allvtx           <boo> whether to output parameters for all verticeis. 
%                      Default to false. Otherwise will only output 
%                      parameters for vertices in the labels.
%
% Created by Haiyang Jin (2023-July-1)

if ~exist('labels', 'var') || isempty(labels)
    evc = cellfun(@(x) sprintf('lh_%s.label', x), ...
        {'V1', 'V2', 'V3', 'V4'}, ... {'V1', 'V2', 'V2d', 'V2v', 'V3', 'V3A', 'V3B', 'V3d', 'V3v', 'V4'}
        'uni', false); 
    % 'roi.lh.f13.face-vs-object.%s.label'
    ffa = cellfun(@(x) sprintf('hemi-lh_type-f13_cont-face=vs=object_roi-%s_froi.label', x), ...
        {'ofa', 'ffa1', 'ffa2', 'atl'}, 'uni', false);
    labels = fullfile('..', 'label', horzcat(evc, ffa));
elseif ischar(labels)
    labels = {labels};
end

if ~exist('allvtx', 'var') || isempty(allvtx); allvtx = false; end 

% identify all the matched files
prfFnList = fs_samsrf_listprfs(prf_wc);

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

oldpath = pwd;
cd(prfpath);

%% labels
% update the hemisphere information
labelboth = cellfun(@(x) strrep(x, {'rh', 'lh'}, {'lh', 'rh'}), labels, 'uni', false);
labelboth = vertcat(labelboth{:});
labels = labelboth(:, 2-strcmp(Srf.Hemisphere, 'lh'));
labels(cellfun(@(x) ~exist(x, 'file'), labels)) = [];
[~, labelFns] = cellfun(@fileparts, labels, 'uni', false);

% read the label
labelMats = cellfun(@fs_readlabel, labels, 'uni', false);
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
