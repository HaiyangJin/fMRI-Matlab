function info_struct = fp_fn2info(filename, secstr, valuestr)
% info_struct = fp_fn2info(filename)
% 
% This function collects the relevant information from the filename by
% secction (<secstr>) and value (<valuestr>) strings.
%
% Inputs:
%    filename        <str> the file name to be parsed.
%    secstr          <str> the string to be used to separate the filename
%                     into different sections. Default is '_'.
%    valuestr        <str> the string to be used to separate each section
%                     into fieldname and value. Only the first valuestr 
%                     will be used. Default is '-'. 
%
% Output:
%    info_struct     <struct> the information in a struct.
%
% % Example 1:
% fp_fn2info('sourcedata/sub-002_ses-001_Run-test');
%
% Created by Haiyang Jin (2021-10-08)

if ~exist('secstr', 'var') || isempty(secstr)
    secstr = '_';
end

if ~exist('valuestr', 'var') || isempty(valuestr)
    valuestr = '-';
end

% backup .gz
if endsWith(filename, '.gz')
    ext2 = '.gz';
    filename = erase(filename, '.gz');
else
    ext2 = '';
end
% remove the path
[~, fname, ext] = fileparts(filename);

% split string by '_' for section (field) and by "-" for value
sec = split(fname, secstr);

% deal with values without fieldname
hasField = cellfun(@(x) contains(x, '-'), sec);
backupFields = arrayfun(@(x) sprintf('custom%d', x), 1:length(sec), 'uni', false)';

if hasField(end)==false && ismember(sec{end}, ...
        {'bold', 'epi', 'T1w', 'T2w', 'scans', 'events'}) % to be confirmed
    backupFields{end} = 'modality';
end
% add backup fieldnames
sec(~hasField) = cellfun(@(x,y) [y '-' x], sec(~hasField), backupFields(~hasField), 'uni', false);

% index of the first '-'
index = cellfun(@(x) x(1), cellfun(@(x) regexp(x, valuestr), sec, 'uni', false));

% fieldnames and values
fieldnm = arrayfun(@(x,y) x{1}(1:y-1), sec, index, 'uni', false);
value = arrayfun(@(x,y) x{1}(y+1:end), sec, index, 'uni', false);

info_struct = cell2struct(value, fieldnm, 1);
info_struct.ext = [ext ext2];

end