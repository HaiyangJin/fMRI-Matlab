function bids_fixfmap(intendList, subjList, fmapwc, bidsDir)
% bids_fixfmap(intendList, subjList, bidsDir)
%
% bids_dcm2bids does not set "intendedFor" in fmap json appropriately (if
% more than 1 func run are available). The run information is missing. This
% function assigns all the func runs in <bidsDir>/<subjCode>/(sess)/funcs
% to "intendedFor" of fmap json files.
%
% Inputs:
%    intendList        <cell str> a list of files to be assigned to
%                       "intendedFor" of fmap json files.
%                   OR <str> wildcard strings to identify the files to be
%                       assigned to "intendedFor" of fmap json files.
%                       Default is '*_run-*bold.nii.gz'.
%    subjList          <cell str> a list of subject folders in <bidsDir>.
%                   OR <str> wildcard strings to match the subject folders
%                       via bids_subjlist(). Default is all subjects.
%    fmapwc            <str> wildcard for the fmap json files, for which
%                       the intendList will be added to. Default is
%                       '*.json', i.e., all json files in fmap/ will be
%                       updated.
%    bidsDir           <str> the BIDS directory. Default is bids_dir().
%
% Output:
%    Updated fmap json files.
%
% Created by Haiyang Jin (2021-10-13)
%
% See also:
% [bids_dcm2bids;] bids_mktsv; bids_fixfunc; bids_mkignore

%% Deal with inputs
if ~exist('intendList', 'var') || isempty(intendList)
    intendList = '*_run-*.nii.gz';
end

if ~exist('bidsDir', 'var') || isempty(bidsDir)
    bidsDir = bids_dir();
end

if ~exist('fmapwc', 'var') || isempty(fmapwc)
    fmapwc = '*.json';
end

if ~exist('subjList', 'var') || isempty(subjList)
    subjList = '';
end
if ischar(subjList)
    subjList = bids_subjlist(subjList, bidsDir);
end
nSubj = length(subjList);
fmapcell = cell(nSubj,1);

%% find all *.json within 'fmap/' for each subject separately
for iSubj = 1:nSubj

    % all file/folders within subject folder
    theSubjdir = dir(fullfile(bidsDir, subjList{iSubj}));

    if contains('fmap', {theSubjdir.name})
        % if there is no sessions
        fmapdir_c = dir(fullfile(bidsDir, subjList{iSubj}, 'fmap', fmapwc));
    else
        % if there are different sessions
        fmapdir_c = cellfun(@(x) ...
            dir(fullfile(bidsDir, subjList{iSubj}, x, 'fmap', fmapwc)), ...
            {theSubjdir.name}, 'uni', false);
        fmapdir_c = vertcat(fmapdir_c{:});
    end

    fmapcell(iSubj, 1) = {fmapdir_c};
end

% save as one struct
fmapdir = vertcat(fmapcell{:});

% update each fmap json file
for ifmap = 1:length(fmapdir)

    thisfname = fullfile(fmapdir(ifmap).folder, fmapdir(ifmap).name);
    val = jsondecode(fileread(thisfname));

    % list of functional and sbref
    if ischar(intendList)
        % only identify the func runs in the same session
        intenddir = dir(fullfile(fmapdir(ifmap).folder, '..', 'func', intendList));
        allintend = fullfile('func', {intenddir.name});
    else
        allintend = intendList;
    end

    val.IntendedFor = allintend;
    str = jsonencode(val);

    % Make the json output file more human readable
    str = strrep(str, ',"', sprintf(',\n"'));
    str = strrep(str, '[{', sprintf('[\n{\n'));
    str = strrep(str, '}]', sprintf('\n}\n]'));

    fid = fopen(thisfname,'w');
    fwrite(fid,str);
    fclose(fid);

end

end