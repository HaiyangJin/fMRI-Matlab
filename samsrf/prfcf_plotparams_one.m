function prfcf_plotparams_one(prfFnList, rois, outpath)


%% Deal with inputs
if ischar(prfFnList); prfFnList = {prfFnList}; end
N_prf = length(prfFnList);

if ~exist('rois', 'var') || isempty(rois)
    rois = cellfun(@(x) sprintf('../label/roi.lh.f13.face-vs-object.%s.label', x), ...
        {'ofa', 'ffa1', 'ffa2', 'atl'}, 'uni', false);
elseif ischar(rois)
    rois = {rois};
end
N_rois = length(rois);

if ~exist('outpath', 'var') || isempty(outpath)
    outpath = pwd;
end
fm_mkdir(outpath);

%% Plot
% make a new figure
f = figure('Position', [1, 1, 500*N_rois, 500*N_prf]);
tiledlayout(N_prf, N_rois);

% all Prf files and all rois
[tmpregion, tmpprflist] = ndgrid(rois, prfFnList);
% make sub-plots
cellfun(@(x,y) plot_params(x, y), tmpprflist(:), tmpregion(:), 'uni', false);


%% Save the plot
% make the file name
[~, fns] = cellfun(@fileparts, prfFnList, 'uni', false);
if length(fns) == 1
    fn = fns{1};
elseif length(fns) > 1
    tmpfns = fns(2:end);
    fn = sprintf('%s%s', fns{1}, sprintf(repmat('~~VS~~%s', length(tmpfns), 1), tmpfns{:}));
end

% update the figure name and save it
set(f, 'Name', fn);
fname = fullfile(outpath, fn);
saveas(f, fname, 'png');

end

%% Sub-function
function plot_params(prfFname, roi)

% ensure the Srf file exists
[prfpath, fn] = fileparts(prfFname);
if ~endsWith(prfpath, 'prf')
    warning('The prf result file does not seem to be in a "prf/" folder.')
end
% load the variables
load(prfFname, 'Srf');
if ~exist('Srf', 'var')
    warning('%s does not contain Srf...', prfFname);
    return
end

% set the camera view and mesh/surface
if strcmp(Srf.Hemisphere, 'rh')
    roi = strrep(roi, 'lh', 'rh');
    if length(regexp(roi, 'rh')) ~= 1
        warning('The label name may not make sense...');
    end
end

if endsWith(roi, '.label')
    roi = strrep(roi, '.label', '');
end

%% Make plots
% change current working directory to prf/
oldpath = pwd;
cd(prfpath);

% each sub-plot
theax = nexttile;
theax.FontSize = 18;

% use 'SigmaN' for Css
if ismember('Exponent', Srf.Values)
    sigma = 'Sigma1';
else
    sigma = 'Sigma';
end

samsrf_plot(Srf, sigma, Srf, 'Eccentricity', 0:10, roi);

% add title and sub-title
theinfo = fp_fn2info(fn);
theinfo = rmfield(theinfo, 'task'); % remove task name
updatedfn = fp_info2fn(theinfo);
title(strrep(updatedfn, '_', '\_'));
[~, roiname, ext] = fileparts(roi);
subtitle([roiname, ext])
set(findall(gcf,'-property','FontSize'),'FontSize',16)

xlim(theax, [0 10]);
ylim(theax, [0, 18]);

% change back to the original directory
cd(oldpath);

end
