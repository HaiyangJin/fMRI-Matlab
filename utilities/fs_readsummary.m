function sumTable = fs_readsummary(sumPathInfo, sumFn, toMNI152, outPath, outFn)
% sumTable = fs_readsummary(filename, sumFn, [toMNI152=0, outPath=pwd, outFn='summary.csv'])
%
% This function reads the summary file generated in FreeSurfer (mainly by
% mri_surfcluster).
%
% Inputs:
%    sumPathInfo     <cell> a 1xQ or Px1 cell. All the path and filename
%                     information to theto-be-printed files. Each row is
%                     one layer (level) ofthe path and all the paths will
%                     be combined in order(with all possible combinations).
%                     [fileInfo will be dealt with fs_fullfile.m]
%    sumFn           <string> the filename of the summary file. Default is
%                     'perm.th30.abs.sig.cluster.summary'.
%    toMNI152        <logical> whether converts the coordinates (from
%                     MNI305) to MNI152 space.
%    outPath         <string> where to save the output images. If outPath 
%                     is 'none', no file will be created. Default is the 
%                     current folder.
%    outFn           <string> the name of the output file. Default is
%                     'summary.csv'.
%
% Output:
%    sumTable        <table> a table of the information in the summary file.
%
% Explanations for each colunn in sumTable
% Analysis(Name1): the analysis name;
% Contrast(Name2): the contrast name;
% ClusterNo: the cluster no within each analysis and contrast; ?L? denotes ?left? and ?R? denotes ?right?;
% Max: indicates the maximum -log10(pvalue) in the cluster;
% VtxMax: is the vertex number at the maximum;
% Sizemm2: surface area (mm^2) of cluster;
% MNI305X(YZ): the talairach (MNI305) coordinate of the maximum;
% CWP: clusterwise p-value. This is the p-value of the cluster;
% CWPLow and CWPHi: 90% confidence interval for CWP;
% NVtxs: number of vertices in cluster;
% WghtVtx: [not sure what it is so far; I haven?t used this information];
% Annot: the annotation of the max response based on -aparc
% MNI152X(YZ): the MNI152 coordinates converted from MNI305X(YZ);
% Hemi: hemisphere
% Bonferroni: 2 means both left and right hemispheres.
% Sign: abs (two-sided tests)
% Threshold: 3 (-log10(pvalue));
% CWPvalue: the minimum final cluster p value to generate the results. 
%
% Created by Haiyang Jin (15-Apr-2020)
%
% See also:
% fs_cvn_print2nd

if ~exist('sumFn', 'var') || isempty(sumFn)
    sumFn = 'perm.th30.abs.sig.cluster.summary';
end
if ~exist('toMNI152', 'var') || isempty(toMNI152)
    toMNI152 = 0;
end
if ~exist('outPath', 'var') || isempty(outPath)
    outPath = fullfile(pwd, 'Summary');
end
if ~exist('outFn', 'var') || isempty(outFn)
    outFn = 'Summary.csv';
end

%% Read the summary files
% create the path to the summary files
sumFiles = fullfile(fs_fullfile(sumPathInfo{:}), sumFn);

% read the summary files
sumTableCell = cellfun(@(x) readsummary(x, toMNI152), sumFiles, 'uni', false);

%% Gather the information for the summary files
% % find which have multiple levels
% isMulti = cellfun(@(x) iscell(x) && numel(x) ~= 1, sumPathInfo);
% multiLevels = sumPathInfo(isMulti);
% 
% % repeat the multiple levels for each table
% [~, levels] = fs_fullfile(multiLevels{:});
% levelCell = [levels{:}];
% levelNames = arrayfun(@(x) sprintf('Name%d', x), 1:size(levelCell, 2), 'uni', false);
% 

[levelCell, levelNames] = fs_pathinfo2table(sumPathInfo);
infoTableCell = arrayfun(@(x) cell2table(repmat(levelCell(x, :), size(sumTableCell{x}, 1), 1), ...
    'VariableNames', levelNames), 1: size(levelCell,1), 'uni', false)';

%% Combine the two tables and save as a file
% combine variable tables and the file information table
if isempty(infoTableCell); infoTableCell = {[]}; end
sumCell = cellfun(@horzcat, infoTableCell, sumTableCell, 'uni', false);
sumTable = vertcat(sumCell{:});

% Save the sumTable as a file
if ~strcmp(outPath, 'none')
    outFile = fullfile(outPath, outFn);
    writetable(sumTable, outFile);
end

end

%% read summary file separately
function theTable = readsummary(filename, toMNI152)

[~, ~, ext] = fileparts(filename);
assert(strcmp(ext, '.summary'), ['The extension of the file has to be '...
    '''.summary'' (not %s)'], ext);

%% Read the data in summary file
[fid, mes] = fopen(filename);
assert(fid ~= -1, mes); % sanity check
dataCell = textscan(fid, '%d%f%d%f%f%f%f%f%f%f%d%f%s', 'CommentStyle', '#');
fclose(fid);

%% Deal with the strings in summary file
% read the strings
strCell = importdata(filename, ' ', 41);
% split each string into multiple strings
splitCell = cellfun(@strsplit, strCell, 'uni', false);
% remove the first string (which is '#')
infoCell = cellfun(@(x) x(2:end), splitCell, 'uni', false);

% obtain the variable names for data
varNames = cellfun(@(x) erase(x, {'(', '^', ')'}), infoCell{41,1}, 'uni', false);
varNames = cellfun(@(x) strrep(x, 'MNI', 'MNI305'), varNames, 'uni', false);

% create the data table
dataTable = table(dataCell{:}, 'VariableNames', varNames);

% add 1 to vertex indices (from FreeSurfer to Matlab)
dataTable.VtxMax = dataTable.VtxMax + 1;

%% Add MNI152 (converted from MNI305)
if toMNI152
    % obtain MNI305 coordinates
    MNI305 = dataTable(:, cellfun(@(x) startsWith(x, 'MNI305'), dataTable.Properties.VariableNames));
    % convert to MNI152 coordinates
    MNI152 = array2table(fs_fsavg2mni(MNI305{:, :}), 'VariableNames', ...
        strrep(MNI305.Properties.VariableNames, '305', '152'));
    % combine MNI152 coordinates to MNI305
    dataTable = horzcat(dataTable, MNI152);
end

%% Obtain other infromation and combine tables
% obtain other information
otherInfo = struct;
otherInfo.Hemi = infoCell{16, 1}(2);
otherInfo.Bonferroni = infoCell{24, 1}{2};
otherInfo.Sign = infoCell{27, 1}{3};
otherInfo.Threshold = infoCell{25, 1}{3};
otherInfo.CWPvalue = infoCell{29, 1}{4};
% save other information as a table
otherTable = repmat(struct2table(otherInfo), size(dataTable, 1), 1);

% combine the data and other information table
theTable = horzcat(dataTable, otherTable);

% add hemi ('l' or 'r') to cluster number
theTable.ClusterNo = arrayfun(@(x, y) [upper(y{1}(1)) num2str(x)], ...
    theTable.ClusterNo, theTable.Hemi, 'uni', false);

end