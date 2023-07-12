function prfcf_vfcoverage_one(prfFnList, labels, clipping, cblim, outpath)
% Plot the visual field coverage for ROIs.
%
% prfFnList     <cell str> a list of pRF result files.
% labels        <str cell> labels for ROIs.

if ischar(prfFnList) && contains(prfFnList, '*')
    prflist = dir(prfFnList);
    prfFnList = fullfile({prflist.folder}, {prflist.name});
elseif ischar(prfFnList)
    prfFnList = {prfFnList}; 
end
assert(~isempty(prfFnList), 'Cannot find any pRF files...');
N_prf = length(prfFnList);

if ~exist('labels', 'var') || isempty(labels)
    labels = [];
    N_label = 4;
else
    N_label = length(labels);
end

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
f = figure('Position', [1, 1, 500*N_label, 500*N_prf]);
tiledlayout(N_prf, N_label);

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
if isempty(labels)
    % default label files
    labelFns = cellfun(@(x) sprintf('roi.%s.f13.face-vs-object.%s', Srf.Hemisphere, x), ...
        {'ofa', 'ffa1', 'ffa2', 'atl'}, 'uni', false);
    labels = fullfile('..', 'label', labelFns);

elseif isnuermic(labels)
    % when labels are vertex indices
    labelFns = arrayfun(@(x) sprintf('roi_%d', x), 1:length(labels), 'uni', false);
    labels = mat2cell(labels, size(labels,1));
end
N_label = length(labels);

% sub-plot for each ROI
for i=1:N_label

    nexttile;
    samsrf_vfcoverage(Srf, 9.3, labels{i}, 0.05, clipping);
    title(labelFns{i})

    if ~isempty(cblim)
        clim(cblim);             % set colorbar limits
    end
end

if ~isempty(prfPath); cd(oldPath); end

end