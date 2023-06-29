function filelist = bids_listfile(filewc, subjCode, modality, isfped)
% List files in BIDS folder or fmriPrep folder. 
% 
% Inputs:
%    filewc       <str> wildcard for identifying files.
%    subjCode     <str> subject code.
%    modality     <str> the modality folder. Default to 'func'.
%    isfped       <boo> whether to identify files in fmriPrep folder.
%                  Defaul to true. If false, this function will identify
%                  files in the BIDS folder.
%
% Output:
%    filelist     <cell str> a list of identified files. 
%
% Created by Haiyang Jin (2023-June-29)

%% Deal with inputs
if ~exist('modality', 'var') || isempty(modality)
    modality = 'func';
end

if ~exist('isfped', 'var') || isempty(isfped)
    isfped = true;
end

if isfped
    baseDir = fullfile(bids_dir(), 'derivatives', 'fmriprep');
else
    baseDir = bids_dir();
end

%% Identify files
% check this subject folder
theSubjDir = dir(fullfile(baseDir, subjCode));

if ismember(modality, {theSubjDir.name})
    % no session folders
    thedir = dir(fullfile(baseDir, subjCode, modality, filewc));
    filelist = fullfile({thedir.folder}, {thedir.name});

else
    % there are session folders
    tmpfilecell = cell(length(theSubjDir), 1);

    for ifolder = 1:length(theSubjDir)
        % find files for each session folder
        thedir = dir(fullfile(baseDir, subjCode, theSubjDir(ifolder).name, modality, filewc));
        tmpfilecell{ifolder,1} = fullfile({thedir.folder}, {thedir.name})';
    end

    filelist = vertcat(tmpfilecell{:});
end

end