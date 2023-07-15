function fs_samsrf_vfcoverage(prfFnList, labels, clipping, cblim, outpath)
% fs_samsrf_vfcoverage(prfFnList, labels, clipping, cblim, outpath)
%
% Plot the visual field coverage for ROIs.
%
% Inputs:
%    prfFnList        <cell str> a list of Srf files to be displayed.
%    labels           <cell str> labels to be displayed. Default to some
%                      label files, e.g., roi.lh.f13.face-vs-object.ofa.label.
%                      If you do not know what this label file refers to,
%                      you probably should set your own lable names. But
%                      the label names have to include the hemisphere
%                      information (e.g., 'lh'), which will be upated to
%                      match the Srf file automatically.
%    clipping         <num> the same color will be displayed for area whose
%                      values are above this. More see samsrf_vfcoverage(). 
%    cblim            <num vec> colorbar limits. Default to defaults in
%                      samsrf_vfcoverage(). 
%    outpath          <str> path to save the output figures. Default to
%                      pwd().
%
% Created by Haiyang Jin (2023-July-1)

if ischar(prfFnList) && contains(prfFnList, '*')
    prflist = dir(prfFnList);
    prfFnList = fullfile({prflist.folder}, {prflist.name});
elseif ischar(prfFnList)
    prfFnList = {prfFnList}; 
end
assert(~isempty(prfFnList), 'Cannot find any pRF files...');
N_prf = length(prfFnList);

if ~exist('labels', 'var') || isempty(labels)
    evc = cellfun(@(x) sprintf('lh_%s.label', x), ...
        {'V1', 'V2', 'V3', 'V4'}, ... {'V1', 'V2', 'V2d', 'V2v', 'V3', 'V3A', 'V3B', 'V3d', 'V3v', 'V4'}
        'uni', false); 
    ffa = cellfun(@(x) sprintf('roi.lh.f13.face-vs-object.%s.label', x), ...
        {'ofa', 'ffa1', 'ffa2', 'atl'}, 'uni', false);
    labels = fullfile('..', 'label', horzcat(evc, ffa));
elseif ischar(labels)
    labels = {labels};
end
N_label_row = min(length(labels), 4);
N_label_col = ceil(length(labels)/N_label_row);

if ~exist('clipping', 'var') || isempty(clipping)
    clipping = Inf;
end

if ~exist('cblim', 'var') || isempty(cblim)
    cblim = [];
end

if ~exist('outpath', 'var') || isempty(outpath)
    outpath = pwd;
end
fm_mkdir(outpath);

%% Make a new figure
f = figure('Position', [1, 1, 500*N_label_row, 500*N_prf*N_label_col]);
tiledlayout(N_prf*N_label_col, N_label_row);

% make plot
cellfun(@(x) vf_coverage(x, labels, clipping, cblim), prfFnList, 'uni', false);

%% Save images
% make the file name
[~, fns] = cellfun(@fileparts, prfFnList, 'uni', false);
if length(fns) == 1
    fn = fns{1};
elseif length(fns) > 1
    tmpfns = fns(2:end);
    fn = sprintf('%s%s', fns{1}, sprintf(repmat('~~VS~~%s', length(tmpfns), 1), tmpfns{:}));
end

if ~isempty(cblim)
    fn = sprintf('%d_%d_%s', cblim(1), cblim(2), fn);
end

if ~isinf(clipping)
    fn = sprintf('%d_%s', clipping*100, fn);
end

set(f, 'Name', fn);
fname = fullfile(outpath, fn);
saveas(f, fname, 'png');

end



%% Local function
function vf_coverage(prfFname, labels, clipping, cblim)
% prfFname    <str> pRF result file.
% labels      <cell> labels for ROIs.
% clipping    <num> see samsrf_vfcoverage()
% cblim       <num> color bar limits

prfPath = fileparts(prfFname);

% change working directory if needed
if ~isempty(prfPath)
    oldPath = pwd;
    cd(prfPath);
end

% load pRF result
load(prfFname, 'Srf');
if ~exist('Srf', 'var')
    warning('%s does not contain Srf...', prfFname);
    return
end

% default labels
if isscalar(labels)
    % when labels are vertex indices
    labelFns = arrayfun(@(x) sprintf('roi_%d', x), 1:length(labels), 'uni', false);
    labels = mat2cell(labels, size(labels,1));
else
    % update the hemisphere information
    labelboth = cellfun(@(x) strrep(x, {'rh', 'lh'}, {'lh', 'rh'}), labels, 'uni', false);
    labelboth = vertcat(labelboth{:});
    labels = labelboth(:, 2-strcmp(Srf.Hemisphere, 'lh'));
    labels(cellfun(@(x) ~exist(x, 'file'), labels)) = [];
    [~, labelFns] = cellfun(@fileparts, labels, 'uni', false);
end
N_label = length(labels);

% sub-plot for each ROI
for i=1:N_label

    nexttile;
    samsrf_vfcoverage(Srf, 9.3, strrep(labels{i}, '.label', ''), 0.05, clipping);
    title(strrep(labelFns{i}, '_', '\_'));

    if ~isempty(cblim)
        clim(cblim);             % set colorbar limits
    end
end

if ~isempty(prfPath); cd(oldPath); end

end