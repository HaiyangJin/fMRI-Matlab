function sumTable = fs_readsummary(filename, toMNI152)
% sumTable = fs_readsummary(filename, [toMNI152=0])
%
% This function reads the summary file generated in FreeSurfer (mainly by
% mri_surfcluster).
%
% Inputs:
%    filename       <string> filename of the summary file (with path).
%    toMNI152       <logical> whether converts the coordinates (from
%                    MNI305) to MNI152 space.
%
% Output:
%    sumTable       <table> a table of the information in the summary file.
%
% Created by Haiyang Jin (15-Apr-2020)

if ~exist('toMNI152', 'var') || isempty(toMNI152)
    toMNI152 = 0;
end

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

%% Add MNI152 (converted from MNI305)
if toMNI152
    % obtain MNI305 coordinates
    MNI305 = dataTable(:, cellfun(@(x) startsWith(x, 'MNI305'), dataTable.Properties.VariableNames));
    % convert to MNI152 coordinates
    MNI152 = array2table(fsavg2mni(MNI305{:, :}), 'VariableNames', ...
        strrep(MNI305.Properties.VariableNames, '305', '152'));
    % combine MNI152 coordinates to MNI305
    dataTable = horzcat(dataTable, MNI152);
end

%% Obtain other infromation and combine tables
% obtain other information
otherInfo = struct;
otherInfo.Hemi = {infoCell{16, 1}{2}};
otherInfo.Bonferroni = infoCell{24, 1}{2};
otherInfo.Sign = infoCell{27, 1}{3};
otherInfo.Threshold = infoCell{25, 1}{3};
otherInfo.CWPvalue = infoCell{29, 1}{4};
% save other information as a table
otherTable = repmat(struct2table(otherInfo), size(dataTable, 1), 1);

% combine the data and other information table
sumTable = horzcat(dataTable, otherTable);

% add hemi ('l' or 'r') to cluster number
sumTable.ClusterNo = arrayfun(@(x, y) [upper(y{1}(1)) num2str(x)], ...
    sumTable.ClusterNo, sumTable.Hemi, 'uni', false);

end