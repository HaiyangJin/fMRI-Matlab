function fp_checkmc(subjCode, tocenter)
% fp_checkmc(subjCode, tocenter)
%
% Check motion (6 motion parameter version) from fmriPrep output.
% More see: https://fmriprep.org/en/stable/outputs.html#confound-regressors-description
%
% Inputs:
%     subjCode         <str> subject code in the fmriPrep folder.
%     tocenter         <bool> whether to center the motion parameters.
%
% Created by Haiyang Jin (2023-6-29)

if nargin < 1
    fprintf('Usage: fp_checkmc(subjCode, tocenter);\n');
    return;
end

% identify all confounds files
filelist = bids_listfile('*desc-confounds_timeseries.tsv', subjCode, 'func', 1);

% check the session information if there is
info = cellfun(@fp_fn2info, filelist);
sess = 0;
seslist = unique({info.ses});
if isfield(info, 'ses'); sess = 1:length(seslist); end

% plot for each session separately
for ises = sess

    if ises==0
        % there is no session folders
        sesname = 'this_run';
        sublist = filelist;
    else

        % session code/name
        sesname = sprintf('ses-%s', seslist{ises});
        % find matched files
        sublist = filelist(contains(filelist, sesname));

    end

    % make figure
    plot_mc(sublist, sesname, tocenter);

end

end

function plot_mc(subfiles, ftitle, tocenter)
% plot motion parameters for each session
%
%   subfiles: <cell str> a list of files
%   ftitle: <str> title to be displayed and saved as the figure.
%   tocenter: <bool> whether to center the motion parameters.

Nruns = length(subfiles);

% initialize a figure
f = figure('Position', [1, 1, 1000, 1000]);
t = tiledlayout(ceil((Nruns+1)/2), 2);
txt = title(t,ftitle);
txt.FontSize = 20;

% plot motion results for each run
for isub = 1:Nruns

    theax = nexttile;
    theax.FontSize = 18;

    % load motion parameters
    thistable = readtable(subfiles{isub}, 'FileType', 'text', 'Delimiter', '\t');
    colnames = {'trans_x', 'trans_y', 'trans_z', 'rot_x', 'rot_y', 'rot_z'};
    thismotion = thistable{:, colnames};

    % center the motion parameters if needed
    if tocenter
        thismotion = thismotion - mean(thismotion, 1);
    end

    % plot it
    x = 1:size(thistable,1);
    plot(x, thismotion)
    % subplot title
    [~, fn, ext] = fileparts(subfiles{isub});
    title(strrep([fn, ext], '_', '\_'));

end

% add legend
lgd = legend('trans\_x', 'trans\_y', 'trans\_z', 'rot\_x', 'rot\_y', 'rot\_z');
lgd.Layout.Tile = Nruns+1;
lgd.NumColumns = 6;
lgd.FontSize = 18;

% link all y axis
tmpaxs = arrayfun(@nexttile, 1:Nruns);
linkaxes(tmpaxs,'y')

% save figure
saveas(f, ftitle, 'png');

end

