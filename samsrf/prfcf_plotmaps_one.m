function prfcf_plotmaps_one(prfFnList, rois, maps, outpath)
% prfcf_plotmaps_one(prfFnList, rois, maps, outpath)
%
% Plots the prf ftting results.
%
% Inputs:
%    prfFnList        <cell str> a list of Srf files to be displayed.
%    rois             <cell str> angles to be displayed/zoomed. Now it
%                      could be 'evc' or 'ffa'. Default to both.
%    maps             <cell str> maps to be dispalyed, e.g., 'R^2',
%                      'Sigma', etc. Default to {'R^2', 'Sigma', 'Polar',
%                      'Eccentricity'};
%    outpath          <str> path to save the output figures. Default to
%                      pwd().
%
% Created by Haiyang Jin (2023-June-30)

%% Deal with inputs
if ischar(prfFnList); prfFnList = {prfFnList}; end
N_prf = length(prfFnList);

if ~exist('rois', 'var') || isempty(rois)
    rois = {'evc', 'ffa'};
elseif ischar(rois)
    rois = {rois};
end
N_region = length(rois);

if ~exist('maps', 'var') || isempty(maps)
    maps = {'R^2', 'Sigma', 'Polar', 'Eccentricity'};
end
N_maps = length(maps);

if ~exist('outpath', 'var') || isempty(outpath)
    outpath = pwd;
end
fm_mkdir(outpath);

%% Plot
% make a new figure
f = figure('Position', [1, 1, 500*N_maps, 500*N_prf*N_region]);
tiledlayout(N_prf*N_region, N_maps);

% all Prf files and all rois
[tmpprflist, tmpregion] = ndgrid(prfFnList, rois);
% make sub-plots
cellfun(@(x,y) plot_maps(x, y, maps), tmpprflist(:), tmpregion(:), 'uni', false);


%% Save the plot
% make the file name
[~, fns] = cellfun(@fileparts, prfFnList, 'uni', false);
if length(fns) == 1
    fn = fns{1};
elseif length(fns) > 1
    tmpfns = fns(2:end);
    fn = sprintf('%s%s', fns{1}, sprintf(repmat('~~VS~~%s', length(tmpfns), 1), tmpfns{:}));
end

if N_region == 1
    region_str = rois{1};
else
    tmprois = rois(2:end);
    region_str = sprintf('%s%s', rois{1}, sprintf('_%s', tmprois{:}));
end

% update the figure name and save it
set(f, 'Name', fn);
fname = fullfile(outpath, [upper(region_str) '_' fn]);
saveas(f, fname, 'png');

end % function prfcf_plotprf

%% Sub-functions
function plot_maps(prfFname, rois, maps)
% prfFname    <str> the file name of the Srf file.
% rois        <str> the region to be displayed: 'evc' or 'ffa'.
% maps        <cell str> maps to be displayed.

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
isleft = strcmp(Srf.Hemisphere, 'lh');
if ischar(rois)
    rois = find(strcmp(rois, {'evc', 'ffa'}));
end
camviews = {[-2.1 -32.5 1.5], [2.2 -37.4 1.5];      % early visual cortex
    [-67.4, -60.6, 1.5], [81.8, -78.4, 1.5]};  % face-selective
camview = camviews{rois, 2-isleft};
meshes = {'sphere', 'inflated'};

%% Make plots
% change current working directory to prf/
oldpath = pwd;
cd(prfpath);

% threshold for R^2 (default in DisplayMaps)
if isfield(Srf, 'Y')
    % If time course is saved
    Pval = 0.0001;
    Tval = tinv(1 - Pval/2, size(Srf.Y,1)-2); % t-statistic for this p-value
    R = sign(Tval) .* (abs(Tval) ./ sqrt(size(Srf.Y,1)-2 + Tval.^2)); % Convert t-testistic into correlation coefficient
    R2Thrsh = R.^2; % Variance explained
else
    R2Thrsh = 0;
end

% labels
labels = cellfun(@(x) sprintf('roi.%s.f13.face-vs-object.%s.label', Srf.Hemisphere, x), ...
    {'ofa', 'ffa1', 'ffa2', 'atl'}, 'uni', false);
labellist = fullfile('..', 'label', labels);

% plot for each map
N_maps = length(maps);
PHcell = cell(N_maps,1);
for imap = 1:N_maps

    % use 'SigmaN' for Css
    thismap = maps{imap};
    if ismember('Exponent', Srf.Values) && strcmp(thismap, 'Sigma')
        thismap = 'Sigma1';
    end

    % set the threshold for this map
    Thrsh = NaN(1,5);
    Thrsh(1) = R2Thrsh;
    switch thismap
        case 'R^2'
            Thrsh(2:3) = [0 1];
        case {'Polar', 'Phase'}
            Thrsh(2:3) = [0 0];
        case 'Eccentricity'
            % Eccentricity
            MapData = sqrt(Srf.Data(2,:).^2 + Srf.Data(3,:).^2);
            Thrsh(2:3) = [0 prctile(MapData(MapData > 0), 95)];
        case {'x0', 'y0', 'Sigma', 'Sigma1'}
            MapData = sqrt(Srf.Data(2,:).^2 + Srf.Data(3,:).^2);
            Thrsh(2:3) = [0 prctile(MapData(MapData > 0), 75)];
        otherwise
            MapData = sqrt(Srf.Data(2,:).^2 + Srf.Data(3,:).^2);
            Thrsh(2:3) = [0 prctile(MapData(MapData > 0), 99)];
    end
    % more thresholds
    Thrsh(4:5) = [0, Inf];

    % each sub-plot
    theax = nexttile;
    theax.FontSize = 18;

    % plot it
    PHcell{imap, 1} = samsrf_surf(Srf, meshes{rois}, Thrsh, labellist, ...
        camview, thismap);
    % add title and sub-title
    theinfo = fp_fn2info(fn);
    theinfo = rmfield(theinfo, 'task'); % remove task name
    updatedfn = fp_info2fn(theinfo);
    title(strrep(updatedfn, '_', '\_'));
    subtitle(sprintf('%s (%d -> %0.4f)', thismap, Thrsh(2), Thrsh(3)));

end

% change back to the original directory
cd(oldpath);

end %function plot_prf
