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
if ~exist('trgSubj', 'var') || isempty(trgSubj)
    trgSubj = {'fsaverage'};
elseif ischar(trgSubj)
    trgSubj = {trgSubj};
end

[tempSSubj, tempSLabel, tempTSubj] = ndgrid(srcSubj, srcLabel, trgSubj);
sSubjList = tempSSubj(:);
sLabelList = tempSLabel(:);
tSubjList = tempTSubj(:);

nComb = numel(sSubjList);

if ~exist('struPath', 'var') || isempty(struPath)
    struPath = getenv('SUBJECTS_DIR');
end
% get the full path to labels
sFileList = fullfile(struPath, sSubjList, 'label', sLabelList); 

if ~exist('trgLabel', 'var') || isempty(trgLabel)
    trgLabel = cellfun(@(x) strrep(x, '.label', '.2fsaverage.label'), sFileList, 'uni', false);
elseif strcmp(trgLabel, 'samename')
    trgLabel = fullfile(struPath, tSubjList, 'label', sLabelList);
elseif ischar(trgLabel)
    trgLabel = {trgLabel};
end
assert(numel(trgLabel) == nComb, ['The number of ''trgLabel'' (%d) '...
    'has to be same as that of ''srcSubj'' (%d).'], numel(trgLabel), nComb);  

if ~exist('runcmd', 'var') || isempty(runcmd)
    runcmd = num2cell(ones(nComb, 1));
elseif numel(runcmd) == 1
    runcmd = num2cell(repmat(runcmd, nComb, 1));
end

% run the fscmd
[fscmds, isnotok] = cellfun(@label2label, sSubjList, sFileList, tSubjList, trgLabel, runcmd, 'uni', false);

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