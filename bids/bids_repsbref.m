function bids_repsbref(sbrefwc, subjList, boldwc, rmSrc, bidsDir)
% bids_repsbref(sbrefwc, subjList, boldwc, rmSrc, bidsDir)
%
% Repeat one single band reference files (*_sbref.nii.gz and *_sbref.json)
% for all the functional BOLD runs. (Probably it is better to collect the
% single band reference for each functional run separately). 
%
% Inputs:
%    sbrefwc           <str> wildcard for identifying the single band 
%                       reference file within each func/ folder.
%    subjList          <cell str> a list of subject folders in <bidsDir>.
%                   OR <str> wildcard strings to match the subject folders
%                       via bids_subjlist(). Default is all subjects.
%    boldwc            <str> wildcard to be used to identify the target 
%                       bold functional runs. Default is '*_bold.nii.gz'.
%    rmSrc             <boo> whether to remove the identified (original) 
%                       single band reference file, default is 1.
%    bidsDir           <str> the BIDS directory. Default is bids_dir().
%
% Output:
%     Repeat the single band reference for all functional runs. 
%
% Created by Haiyang Jin (2022-April-14)

if nargin < 1
    fprintf('Usage: ');
    return;
end

if ~exist('bidsDir', 'var') || isempty(bidsDir)
    bidsDir = bids_dir();
end

if ~exist('boldwc', 'var') || isempty(boldwc)
    boldwc = '*_bold.nii.gz';
end

if ~exist('rmSrc', 'var') || isempty(rmSrc)
    rmSrc = 0;
end

if ~exist('subjList', 'var') || isempty(subjList)
    subjList = '';
end
if ischar(subjList)
    subjList = bids_subjlist(subjList, bidsDir);
end
nSubj = length(subjList);
funccell = cell(nSubj, 1);

%% Repeat the files

% find all the 'func/' folders for all subjects
for iSubj = 1:nSubj

    theSubjdir = dir(fullfile(bidsDir, subjList{iSubj}));

    if contains('func', {theSubjdir.name})
        % when there is no session folders
        funcdir_c = dir(fullfile(bidsDir, subjList{iSubj}, 'func*'));
    else
        % when there are session folders
        funcdir_c = cellfun(@(x) ...
            dir(fullfile(bidsDir, subjList{iSubj}, x, 'func*')), ...
            {theSubjdir.name}, 'uni', false);
        funcdir_c = vertcat(funcdir_c{:});
    end

    funccell(iSubj, 1) = {funcdir_c};
end

% the whole list of func folders
funcdir = vertcat(funccell{:});

for ifunc = 1:length(funcdir)

    %%% deal with the *_sbref.nii.gz
    % identify the only appropriate single band reference file
    thissbdir = dir(fullfile(funcdir(ifunc).folder, funcdir(ifunc).name, sbrefwc));

    assert(length(thissbdir)==1, ['More than one single band reference ' ...
        'has been identified in %s...'], funcdir(ifunc).folder);
    niisrc = fullfile(thissbdir.folder, thissbdir.name);

    % identify all the bold run files
    thebolddir = dir(fullfile(funcdir(ifunc).folder, funcdir(ifunc).name, boldwc));
    niitrg = cellfun(@(x) strrep(x, '_bold.nii.gz', '_sbref.nii.gz'), ...
        {thebolddir.name}, 'uni', false);

    % repeat the single band reference file
    cellfun(@(x) copyfile(niisrc, x), fullfile({thebolddir.folder}, niitrg), 'uni', false);
    if rmSrc; delete(niisrc); end

    %%% deal with the *.sbref.json
    jsonsrc = strrep(niisrc, '.nii.gz', '.json');
    jsontrg = cellfun(@(x) strrep(x, '.nii.gz', '.json'), ...
        fullfile({thebolddir.folder}, niitrg), 'uni', false);

    cellfun(@(x) copyfile(jsonsrc, x), jsontrg, 'uni', false);
    if rmSrc; delete(jsonsrc); end
end

end