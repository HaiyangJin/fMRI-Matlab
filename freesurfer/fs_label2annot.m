function [fscmd, isnotok] = fs_label2annot(trgSubj, hemi, labelList, annotFn)
% [fscmd, isnotok] = fs_label2annot(trgSubj, hemi, labelList, annotFn)
%
% This function saves multiple labels into one annot(ation) file. [This is
% useful for displaying multiple labels in FreeSurfer.] [But the overlap
% will be overwirtten.]
%
% Inputs:
%    trgSubj         <string> the target subject code.
%    hemi            <string> hemisphere ('lh' or 'rh').
%    labelList       <cell string> list of labels to be saved in the annot
%                     file.
%    annotFn         <string> the filename of the to-be-saved annot file
%                     (will be saved in label/).
%
% Output:
%    fscmd           <cell string> FreeSurfer commands run in the current
%                     session.
%    isnotok         <logical> whether fscmd failed (0: not failed).
%    a new annot file saved in label/.
%
% Created by Haiyang Jin (4-Nov-2020)

labelPath = fullfile(getenv('SUBJECTS_DIR'), trgSubj, 'label');

if ischar(labelList)
    labelList = {labelList};
    warning('Only one label file will be saved in the annot file.');
end
nLabel = numel(labelList);

% add path if there is label filename only
includePath = cellfun(@(x) any(filesep == x), labelList);
labelList(~includePath) = fullfile(labelPath, labelList(~includePath));

% create fscmd for labels
fscmd_label = sprintf(repmat('--l %s ', 1, nLabel), labelList{:});

% deal with annotFile
if ~exist('annotFn', 'var') || isempty(annotFn)
    annotFn = 'temporary.annot';
elseif ~endsWith(annotFn, '.annot')
    annotFn = [annotFn '.annot'];
end
if ~any(filesep == annotFn)
    annotFn = fullfile(labelPath, annotFn);
end

% create and perform fscmd
fscmd = sprintf('mris_label2annot --ctab %s --s %s --h %s --annot-path %s %s',...
    fullfile(getenv('FREESURFER_HOME'), 'FreeSurferColorLUT.txt'),...
    trgSubj, hemi, annotFn, fscmd_label);

isnotok = system(fscmd);

end