function fs_samsrf_plotparams(prfFnList, labels, outpath, showfig)
% fs_samsrf_plotparams(prfFnList, labels, outpath, showfig)
%
% Plot Sigma against Eccentricity (will make it more flexible later).
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
%    outpath          <str> path to save the output figures. Default to
%                      pwd().
%    showfig          <bool> whether to show the figure, default to true.
%
% Created by Haiyang Jin (2023-July-1)

%% Deal with inputs
if ischar(prfFnList); prfFnList = {prfFnList}; end
N_prf = length(prfFnList);

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
N_label_row = min(length(labels), 4);
N_label_col = ceil(length(labels)/N_label_row);

if ~exist('outpath', 'var') || isempty(outpath)
    outpath = pwd;
end
fm_mkdir(outpath);

if ~exist('showfig', 'var') || isempty(showfig)
    showfig = true;
end
showfigs = {'on', 'off'};

%% Plot
% make a new figure
f = figure('Position', [1, 1, 500*N_label_row, 500*N_prf*N_label_col], ...
    'Visible', showfigs{2-showfig});
tiledlayout(N_prf*N_label_col, N_label_row);

% make sub-plots
cellfun(@(x,y) plot_params(x, labels), prfFnList, 'uni', false);

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

if ~showfig; close(f); end

end



%% Local function
function plot_params(prfFname, labels)

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
theinfo = fp_fn2info(fn);
theinfo = rmfield(theinfo, 'task'); % remove task name
updatedfn = fp_info2fn(theinfo);

% update the hemisphere information
labelboth = cellfun(@(x) strrep(x, {'rh', 'lh'}, {'lh', 'rh'}), labels, 'uni', false);
labelboth = vertcat(labelboth{:});
labels = labelboth(:, 2-strcmp(Srf.Hemisphere, 'lh'));
[~, labelFns] = cellfun(@fileparts, labels, 'uni', false);
N_label = length(labels);

%% Make plots
% change current working directory to prf/
oldpath = pwd;
cd(prfpath);

% use 'SigmaN' for Css
if ismember('Exponent', Srf.Values)
    sigma = 'Sigma1';
else
    sigma = 'Sigma';
end

% sub-plot for each label/ROI
for i = 1:N_label

    % each sub-plot
    theax = nexttile;
    theax.FontSize = 18;

    thislable = labels{i};

    % process the label name
    info = fp_fn2info(thislable);
    if isfield(info, 'hemi')
        % shorten the label name
        values = cellfun(@(x) info.(x), fieldnames(info), 'uni', false);
        labelFn = strjoin(values(1:end-1), '_');
    else
        labelFn = labelFns{i};
    end
    
    if exist(thislable, 'file')
        samsrf_plot(Srf, sigma, Srf, 'Eccentricity', 0:10, strrep(thislable, '.label', ''));
        subtitlestr = labelFn;
    else
        subtitlestr = [labelFn, ' (N.A.)'];
    end

    % add title and sub-title
    title(strrep(updatedfn, '_', '\_'));
    subtitle(strrep(subtitlestr, '_', '\_'));
    set(findall(gcf,'-property','FontSize'),'FontSize',16)

    xlim(theax, [0 10]);
    ylim(theax, [0, 18]);

end

% change back to the original directory
cd(oldpath);

end
