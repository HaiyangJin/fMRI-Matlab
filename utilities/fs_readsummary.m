function sumTable = fs_readsummary(filename)
% sumTable = fs_readsummary(filename)
%
% This function reads the summary file generated in FreeSurfer (mainly by 
% mri_surfcluster).
%
% Input:
%    filename       <string> filename of the summary file (with path).
%
% Output:
%    sumTable       <table> a table of the information in the summary file.
%
% Created by Haiyang Jin (15-Apr-2020)

[~, ~, ext] = fileparts(filename);
assert(strcmp(ext, '.summary'), ['The extension of the file has to be '...
    '''.summary'' (not %s)'], ext);

%% read the data in summary file
[fid, mes] = fopen(filename); 
assert(fid ~= -1, mes); % sanity check
dataCell = textscan(fid, '%d%f%d%f%f%f%f%f%f%f%d%f%s', 'CommentStyle', '#'); 
fclose(fid);

%% deal with the strings in summary file
% read the strings
strCell = importdata(filename, ' ', 41);
% split each string into multiple strings
splitCell = cellfun(@strsplit, strCell, 'uni', false);
% remove the first string (which is '#')
infoCell = cellfun(@(x) x(2:end), splitCell, 'uni', false);

% obtain the variable names for data
varNames = cellfun(@(x) erase(x, {'(', '^', ')'}), infoCell{41,1}, 'uni', false);
% create the data table
dataTable = table(dataCell{:}, 'VariableNames', varNames);

% obtain other information
otherInfo = struct;
otherInfo.Hemi = infoCell{16, 1}{2};
otherInfo.Bonferroni = infoCell{24, 1}{2};
otherInfo.Sign = infoCell{27, 1}{3};
otherInfo.Threshold = infoCell{25, 1}{3};
otherInfo.CWPvalue = infoCell{29, 1}{4};
% save other information as a table
otherTable = repmat(struct2table(otherInfo), size(dataTable, 1), 1);

% combine the data and other information table
sumTable = horzcat(dataTable, otherTable);

end
