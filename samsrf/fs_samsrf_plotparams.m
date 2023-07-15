function fs_samsrf_plotparams(prfFnList, labels, outpath)
% fs_samsrf_plotparams(prfFnList, labels, outpath)
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
%
% Created by Haiyang Jin (2023-July-1)

%% Deal with inputs
if ischar(prfFnList); prfFnList = {prfFnList}; end
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

if ~exist('outpath', 'var') || isempty(outpath)
    outpath = pwd;
end
fm_mkdir(outpath);

%% Plot
% make a new figure
f = figure('Position', [1, 1, 500*N_label_row, 500*N_prf*N_label_col]);
tiledlayout(N_prf*N_label_col, N_label_row);

% all Prf files and all labels
[tmpregion, tmpprflist] = ndgrid(labels, prfFnList);
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



%% Local function
function plot_params(prfFname, label)

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

% update the hemisphere information
labelboth = strrep(label, {'rh', 'lh'}, {'lh', 'rh'});
label = labelboth{1, 2-strcmp(Srf.Hemisphere, 'lh')};
[~, labelname, ext] = fileparts(label);

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

if exist(label, 'file')
    samsrf_plot(Srf, sigma, Srf, 'Eccentricity', 0:10, strrep(label, '.label', ''));
    subtitlestr = [labelname, ext];
else
    subtitlestr = [labelname, ext, ' (N.A.)'];
end

% add title and sub-title
theinfo = fp_fn2info(fn);
theinfo = rmfield(theinfo, 'task'); % remove task name
updatedfn = fp_info2fn(theinfo);
title(strrep(updatedfn, '_', '\_'));
subtitle(strrep(subtitlestr, '_', '\_'));
set(findall(gcf,'-property','FontSize'),'FontSize',16)

xlim(theax, [0 10]);
ylim(theax, [0, 18]);

% change back to the original directory
cd(oldpath);

end
