function info_struct = fp_fn2info(filename, secsep, valuesep, modality)
% info_struct = fp_fn2info(filename, secsep, valuesep, modality)
%
% This function collects the relevant information from the filename by
% secction (<secstr>) and value (<valuestr>) strings.
%
% Inputs:
%    filename        <str> the file name to be parsed.
%    secsep          <str> the string to be used to separate the filename
%                     into different sections. Default is '_'.
%    valuesep        <str> the string to be used to separate each section
%                     into fieldname and value. Only the first valuestr
%                     will be used. Default is '-'.
%    modality        <cell str> a list of strings to be identified as
%                     'modality'. Other strings will be identified as
%                     'format*'. Default is provided. 
%
% Output:
%    info_struct     <struct> the information in a struct.
%
% % Example 1:
% info = fp_fn2info('sub-002_TaskName_ses-001_Run-01_bold.nii.gz');
%
% % Example 2:
% info = fp_fn2info('sub-S02_task-TN_run-4_space-fsnative_hemi-L_bold.func.gii');
%
% % Example 3:
% info = fp_fn2info('sub-1_task-S_run-4_space-fsLR_den-91k_bold.dtseries.nii');
%
% Created by Haiyang Jin (2021-10-08)
%
% See also:
% fp_info2fn

if ~exist('modality', 'var') || isempty(modality)
    modality = {'bold', 'sbref', 'epi', 'T1w', 'T2w', ...
        'scans', 'events', ...
        'inflated', 'midthickness', 'pial', 'smoothwm', 'probseg', ...
        'timeseries', 'xfm', 'boldref', 'dseg', 'mask'};
end

if ~exist('secsep', 'var') || isempty(secsep)
    secsep = '_';
end

if ~exist('valuesep', 'var') || isempty(valuesep)
    valuesep = '-';
end

%% Deal with extension
% remove the path
[~, fname, ext] = fileparts(filename);
fname = [fname ext];

% strings after the first '.' are regarded as extension
idx = regexp(fname, '\.');
ext = fname(idx:end);

%% Gather information
% split string by '_' for section (field) and by "-" for value
sec = split(fname(1:idx-1), secsep);

% deal with values without fieldname
hasField = cellfun(@(x) contains(x, '-'), sec);
backupFields = arrayfun(@(x) sprintf('custom%d', x), 1:length(sec), 'uni', false)';

if hasField(end)==false && ismember(sec{end}, modality) 
    backupFields{end} = 'modality';
end
% add backup fieldnames
sec(~hasField) = cellfun(@(x,y) [y '-' x], sec(~hasField), backupFields(~hasField), 'uni', false);

% index of the first '-'
index = cellfun(@(x) x(1), cellfun(@(x) regexp(x, valuesep), sec, 'uni', false));

% fieldnames and values
fieldnm = arrayfun(@(x,y) x{1}(1:y-1), sec, index, 'uni', false);
value = arrayfun(@(x,y) x{1}(y+1:end), sec, index, 'uni', false);

info_struct = cell2struct(value, fieldnm, 1);
info_struct.ext = ext;

end