function filename = fp_info2fn(info_struct, secsep, valuesep)
% filename = fp_info2fn(info_struct, secsep, valuesep)
%
% This function converts info_struct (can be obtained via fp_fn2info) into
% a filename (str).
%
% Inputs:
%    info_struct     <struct> the information in a struct.
%    secsep          <str> the string to be used to separate the filename
%                     into different sections. Default is '_'.
%    valuesep        <str> the string to be used to separate each section
%                     into fieldname and value. Only the first valuestr
%                     will be used. Default is '-'.
%
% Output:
%    filename        <str> the output filename.
%
% % Example 1:
% info_struct = fp_fn2info('sub-002_TaskName_ses-001_Run-01_bold.nii.gz');
% fp_info2fn(info_struct);
%
% Created by Haiyang Jin (2021-10-08)
%
% See also:
% fp_fn2info

if ~exist('secsep', 'var') || isempty(secsep)
    secsep = '_';
end

if ~exist('valuesep', 'var') || isempty(valuesep)
    valuesep = '-';
end

% backup the extension
if isfield(info_struct, 'ext')
    ext = info_struct.ext;
    info_struct = rmfield(info_struct, 'ext');
else
    ext = '';
end

% add the sep strings
values = cellfun(@(x) [x secsep], struct2cell(info_struct), 'uni', false);
fields = cellfun(@(x) [x valuesep], fieldnames(info_struct), 'uni', false);

% remove custom* and modality
is2rm = startsWith(fields, {'custom', 'modality'});
fields(is2rm) = {''};

% combine strings and save it as filename
infoCell = horzcat(fields, values);
secCell = arrayfun(@(x) [infoCell{x, 1} infoCell{x, 2}], 1:size(infoCell,1), 'uni', false);
fullfn = sprintf('%s', secCell{:});
filename = [fullfn(1:end-1) ext];

end