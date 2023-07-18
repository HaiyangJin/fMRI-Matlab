function fs_samsrf_plotmaps(prfFnList, rois, maps, labels, thresh, outpath, showfig)
% fs_samsrf_plotmaps(prfFnList, rois, maps, labels, thresh, outpath, showfig)
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
%    labels           <cell str> labels to be displayed. Default to some
%                      label files, e.g., roi.lh.f13.face-vs-object.ofa.label.
%                      If you do not know what this label file refers to,
%                      you probably should set your own lable names. But
%                      the label names have to include the hemisphere
%                      information (e.g., 'lh'), which will be upated to
%                      match the Srf file automatically.
%    thresh           <num vec> 
%    outpath          <str> path to save the output figures. Default to
%                      pwd().
%    showfig          <bool> whether to show the figure, default to true.
%
% Created by Haiyang Jin (2023-July-1)

%% Deal with inputs
if ischar(prfFnList); prfFnList = {prfFnList}; end
N_prf = length(prfFnList);

% camera angle
if ~exist('rois', 'var') || isempty(rois)
    rois = {'evc', 'ffa'};
elseif ischar(rois)
    rois = {rois};
end
N_region = length(rois);

% maps to be displayed
if ~exist('maps', 'var') || isempty(maps)
    maps = {'R^2', 'Sigma', 'Polar', 'Eccentricity'};
end
N_maps = length(maps);

% labels to be displayed
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

if ~exist('outpath', 'var') || isempty(outpath)
    outpath = pwd;
end
fm_mkdir(outpath);

if ~exist('showfig', 'var') || isempty(showfig)
    showfig = true;
end
showfigs = {'on', 'off'};

%% Threshold for all pRF
if ~exist('thresh', 'var') || isempty(thresh)
    threshs = NaN(N_prf, 4);
    for isrf = 1:N_prf
        thisSrf = load(prfFnList{isrf}, 'Srf');
        threshs(isrf, :) = cal_thresh(thisSrf.Srf);
    end

    thresh = max(threshs, [], 1);
    thresh(1) = min(threshs(:,1));
end

%% Plot
% make a new figure
f = figure('Position', [1, 1, 500*N_maps, 500*N_prf*N_region], ...
    'Visible', showfigs{2-showfig});
tiledlayout(N_prf*N_region, N_maps);

% all Prf files and all rois
[tmpprflist, tmpregion] = ndgrid(prfFnList, rois);
% make sub-plots
cellfun(@(x,y) plot_maps(x, y, maps, labels, thresh), tmpprflist(:), tmpregion(:), 'uni', false);

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

if ~showfig; close(f); end

end % function prfcf_plotprf




%% Local-function
function plot_maps(prfFname, rois, maps, labels, thresh)
% prfFname    <str> the file name of the Srf file.
% rois        <str> the region to be displayed: 'evc' or 'ffa'.
% maps        <cell str> maps to be displayed, e.g., 'Sigma'.
% labels      <cell str> labels to be displayed.
% thresh      <num vec> thresholds for the maps.
%               thresh(1): thresohld for R^2
%               thresh(2): (maximum) thresholds for 'Eccentricity'
%               thresh(3): (maximum) thresholds for {'x0', 'y0', 'Sigma', 'Sigma1'}
%               thresh(4): (maximum) thresholds for others.

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

% update the hemisphere in label file names
labelboth = cellfun(@(x) strrep(x, {'rh', 'lh'}, {'lh', 'rh'}), labels, 'uni', false);
labelboth = vertcat(labelboth{:});
labellist = labelboth(:, 2-strcmp(Srf.Hemisphere, 'lh'));

% ensure the length of `thresh` is 4
thresh_default = NaN(1, 4);
if ~exist('thresh', 'var') || isempty(thresh)
    thresh = thresh_default;
elseif length(thresh)<5
    thresh_default(1:length(thresh)) = thresh;
    thresh = thresh_default;
end

%% Make plots
% change current working directory to prf/
oldpath = pwd;
cd(prfpath);

% Calculate default threshold (default in DisplayMaps)
threshs = cal_thresh(Srf);
R2Thrsh = threshs(1);
SrfData75 = threshs(2);
SrfData95 = threshs(3);
SrfData99 = threshs(4);

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
    Thrsh = NaN(1, 5);
    if isempty(thresh(1)) || isnan(thresh(1))
        Thrsh(1) = R2Thrsh;
    else
        Thrsh(1) = thresh(1); % custom threshold
    end
    switch thismap
        case 'R^2'
            Thrsh(2:3) = [0 1];
        case {'Polar', 'Phase'}
            Thrsh(2:3) = [0 0];
        case 'Eccentricity'
            if isempty(thresh(2)) || isnan(thresh(2))
                Thrsh(2:3) = [0 SrfData95];
            else
                Thrsh(2:3) = [0 thresh(2)];
            end
        case {'x0', 'y0', 'Sigma', 'Sigma1'}
            if isempty(thresh(3)) || isnan(thresh(3))
                Thrsh(2:3) = [0 SrfData75];
            else
                Thrsh(2:3) = [0 thresh(3)];
            end
        otherwise
            if isempty(thresh(4)) || isnan(thresh(4))
                Thrsh(2:3) = [0 SrfData99];
            else
                Thrsh(2:3) = [0 thresh(4)];
            end
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

end %local function plot_prf
