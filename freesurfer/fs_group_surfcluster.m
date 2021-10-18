function [slTable, fscmd] = fs_group_surfcluster(pathInfo, varargin)
% [slTable, isok, fscmd] = fs_group_surfcluster(pathInfo, varargin)
%
% This function clusterizes the group level results (e.g., univariate group
% or searchlight results), gathers the corresponding information, and 
% summarizes, saves the results.
%
% Inputs:
%    pathInfo        <cell> a 1xQ or Px1 cell. All the path and filename
%                     information to theto-be-printed files. Each row is
%                     one layer (level) ofthe path and all the paths will
%                     be combined in order(with all possible combinations).
%                     [fileInfo will be dealt with fm_fullfile.m]
%
% Varargin:
%    .runfscmd       <logical> whether run surfcluster in FreeSurfer.
%                     Default is 1.
%    .sigfn          <string> the filename of the summary file. Default is
%                     'sl.libsvm.acc.mgz'.
%    .tomni152       <logical> whether converts the coordinates (from
%                     MNI305) to MNI152 space. Default is 1.
%    .outfile        <string> the full name of the output csv file. Default
%                     is saved current folder with name of 'sl_summary.csv'.
%    .aparc          <string> the atlas to use. Default is 'aparc'.
%    .thmin          <numeric> the minimum value (threshold) to be inclued
%                     in the clusters. Default is 1.96. [It is the
%                     two-tailed p-value of 0.05].
%    .nspace         <integer> N for bonferroni corrections. Default is 2,
%                     i.e., for 'lh' and 'rh'.
%    .surftype       <string> the surface used to calcualte the area etc.
%                     Default is 'white'.
%
% Output:
%    slTable         <table> the summarized information of the searchlight
%                     results.
%    fscmd           <cell strings> fscmd used for surfcluster.
%
% % Explanations for each colunn in slTable
% Analysis(Name1): the analysis name;
% Contrast(Name2): the contrast name;
% ClusterNo: the cluster no within each analysis and contrast; ?L? denotes ?left? and ?R? denotes ?right?;
% Max: indicates the maximum -log10(pvalue) in the cluster;
% VtxMax: is the vertex number at the maximum;
% Sizemm2: surface area (mm^2) of cluster;
% MNI305X(YZ): the talairach (MNI305) coordinate of the maximum;
% NVtxs: number of vertices in cluster;
% WghtVtx: [not sure what it is so far; I haven't used this information];
% Annot: the annotation of the max response based on -aparc
% MNI152X(YZ): the MNI152 coordinates converted from MNI305X(YZ);
%
% Created by Haiyang Jin (3-Nov-2020)
%
% See also:
% fs_cvn_print2nd, fs_surfcluster

% default options
defaultOpts = struct();
defaultOpts.runfscmd = 1;
defaultOpts.sigfn = 'sl.libsvm.acc.mgz';
defaultOpts.tomni152 = 1;
defaultOpts.outfile = fullfile(pwd, 'sl_summary.csv');
defaultOpts.aparc = 'aparc';
defaultOpts.thmin = 1.96; % z values
defaultOpts.nspace = 2;
defaultOpts.surftype = 'white';

opts = fm_mergestruct(defaultOpts, varargin{:});

% create the full path to the files
slFiles = fm_fullfile(pathInfo{:}, opts.sigfn);
% gather the conditions
[levelCell, levelNames] = fm_pathinfo2table(pathInfo);

% the first part of the command (filenames)
fscmd1 = cellfun(@(x) sprintf(['mri_surfcluster '...
    '--in %1$s '...
    '--sum %1$s.csv '...
    '--ocn %1$s.mgh '...
    '--oannot %1$s.annot '...
    '--o %1$s.masked.mgh '...
    ], x), slFiles, 'uni', false);

% the second part of the command (parameter settings)
hemis = cellfun(@fm_2hemi, levelCell(:, end-1), 'uni', false);
fscmd2 = cellfun(@(x) sprintf(['--annot %s --thmin %d --bonferroni %d '...
    '--surf %s --subject fsaverage --hemi %s --nofixmni '], ...
    opts.aparc, opts.thmin, opts.nspace,...
    opts.surftype, x), hemis, 'uni', false);

% combine  and run fscmd
fscmd = cellfun(@(x, y) [x y], fscmd1, fscmd2, 'uni', false);

if opts.runfscmd
    isnotok = cellfun(@system, fscmd);
else
    isnotok = NaN(size(fscmd));
end
fscmd = [fscmd, num2cell(isnotok)];


% read the output files from surfcluster
ctableCell = cellfun(@(x) readoutfn([x '.csv'], opts.tomni152), slFiles, 'uni', false);
% add the condition information
infoTableCell = arrayfun(@(x) cell2table(repmat(levelCell(x, :), size(ctableCell{x}, 1), 1), ...
    'VariableNames', levelNames), 1: size(levelCell,1), 'uni', false)';

% combine variable tables and the file information table
if isempty(infoTableCell); infoTableCell = {[]}; end
slCell = cellfun(@horzcat, infoTableCell, ctableCell, 'uni', false);
slTable = vertcat(slCell{:});

% add the minimum threshold
slTable.thmin = repmat(opts.thmin, size(slTable, 1), 1);
slTable.datafile = repmat({opts.sigfn}, size(slTable, 1), 1);

% Save the sumTable as a file
if ~strcmp(opts.outfile, 'none')
    if ~endsWith(opts.outfile, {'.csv', '.xlsx'})
        opts.outfile = [opts.outfile, '_sl_summary.csv'];
    end
    writetable(slTable, opts.outfile);
end

end

%% load the output file from mri_surfcluster
function clusterTable = readoutfn(outFn, toMNI152)

% Read the data in the output file
[fid, mes] = fopen(outFn);
assert(fid ~= -1, mes); % sanity check
dataCell = textscan(fid, '%d%f%d%f%f%f%f%d%f%s', 'CommentStyle', '#');
fclose(fid);

% obtain the column names
strCell = importdata(outFn, ' ', 36);
splitCell = cellfun(@strsplit, strCell, 'uni', false);
infoCell = cellfun(@(x) x(2:end), splitCell, 'uni', false);

varNames = cellfun(@(x) erase(x, {'(', '^', ')'}), infoCell{35,1}, 'uni', false);
varNames = cellfun(@(x) strrep(x, 'MNI', 'MNI305'), varNames, 'uni', false);

% create the data table
clusterTable = table(dataCell{:}, 'VariableNames', varNames);

% Add MNI152 (converted from MNI305)
if toMNI152
    % obtain MNI305 coordinates
    MNI305 = clusterTable(:, cellfun(@(x) startsWith(x, 'MNI305'), clusterTable.Properties.VariableNames));
    % convert to MNI152 coordinates
    MNI152 = array2table(fs_fsavg2mni(MNI305{:, :}), 'VariableNames', ...
        strrep(MNI305.Properties.VariableNames, '305', '152'));
    % combine MNI152 coordinates to MNI305
    clusterTable = horzcat(clusterTable, MNI152);
end

end