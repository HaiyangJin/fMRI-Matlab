function fscmd = fs_label2label(srcSubj, srcLabel, trgSubj, trgLabel, runcmd, struPath)
% fscmd = fs_label2label(srcSubj, srcLabel, trgSubj, trgLabel, runcmd, struPath)
%
% This fucntion converts the label from one space to another via FreeSurfer
% commands (mri_label2label). . By default, it will convert the label to 
% fsaverage space (but still saved in that subject folder).
%
% Inputs:
%    srcSubj      <cell string> list of source subject codes.
%    srcLabel     <cell string> list of source label files.
%    trgSubj      <cell string> the target subject. Default is 'fsaverage'.
%    trgLabel     <cell string> the names of the target labels. By default,
%                  '.2fsaverage' will be added before '.label'.
%    runcmd       <logical> 1: run and output FreeSurfer commands (fscmd);
%                  0: do not run but only output fscmd.
%    struPath     <string> the path to the subjects folder. Default is
%                  $SUBJECTS_DIR.
%
% Outputs:
%    fscmd        <cell of strings> The first column is FreeSurfer 
%                  commands used in the current session. And the  
%                  second column is whether the command successed. 
%                  [0: successed; other numbers: failed.] 
%
% Created by Haiyang Jin (29-Apr-2020)

%% Deal with inputs
% get a list of all combinations of source subject code and source label
if ischar(srcSubj); srcSubj = {srcSubj}; end
if ischar(srcLabel); srcLabel = {srcLabel}; end
tempSSubj = ndgrid(srcSubj, srcLabel);
sSubjList = tempSSubj(:);
nSSubj = numel(sSubjList);

if ~exist('struPath', 'var') || isempty(struPath)
    struPath = getenv('SUBJECTS_DIR');
end

% get the full path to labels
sLabelList = fs_fullfile(struPath, srcSubj, 'label', srcLabel);

if ~exist('trgSubj', 'var') || isempty(trgSubj)
    trgSubj = repmat({'fsaverage'}, size(sSubjList));
elseif ischar(trgSubj)
    trgSubj = {trgSubj};
end
assert(numel(trgSubj) == nSSubj, ['The number of ''trgSubj'' (%d) '...
    'has to be same as that of ''srcSubj'' (%d).'], numel(trgSubj), nSSubj);  

if ~exist('trgLabel', 'var') || isempty(trgLabel)
    trgLabel = cellfun(@(x) strrep(x, '.label', '.2fsaverage.label'), sLabelList, 'uni', false);
elseif ischar(trgLabel)
    trgLabel = {trgLabel};
end
assert(numel(trgLabel) == nSSubj, ['The number of ''trgLabel'' (%d) '...
    'has to be same as that of ''srcSubj'' (%d).'], numel(trgLabel), nSSubj);  

if ~exist('runcmd', 'var') || isempty(runcmd)
    runcmd = num2cell(ones(size(sSubjList)));
elseif numel(runcmd) == 1
    runcmd = num2cell(repmat(runcmd, size(sSubjList)));
end

% run the fscmd
[fscmds, isnotok] = cellfun(@label2label, sSubjList, sLabelList, trgSubj, trgLabel, runcmd, 'uni', false);

% make the fscmd one column
fscmd = [fscmds, isnotok];

end

% run fscmd individually
function [fscmd, isnotok] = label2label(sSubj, sLabel, tSubj, tLable, runcmd)

hemi = fs_2hemi(sLabel);

% create the FreeSurfer commands
fscmd = sprintf(['mri_label2label --srclabel %s --srcsubject %s '...
    '--trglabel %s --trgsubject %s --regmethod surface --hemi %s'], ...
    sLabel, sSubj, tLable, tSubj, hemi);

if runcmd 
    isnotok = system(fscmd); 
else
    isnotok = zeros(size(fscmd));
end

end