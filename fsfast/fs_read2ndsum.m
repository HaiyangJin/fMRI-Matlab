function sumTable = fs_read2ndsum(groupName, anaList, conList, glmFolder, ...
    statName, sumFn, funcDir)
% sumTable = fs_read2ndsum(groupName, anaList, [conList='', glmFolder='glm-group', ...
%    statName='osgm', sumFn='perm.th30.abs.sig.cluster.summary', funcDir])
%
% This function pools all the summary file (sumFn) together. 
%
% Inputs:
%    groupName        <str> the name of the group folder.
%    anaList          <cell str> list of the analysis names within 
%                      groupName.
%    conList          <cell str> list of the contrast names within
%                      anaList. Default is '' and all the contrasts in the
%                      analysis folders will be used.
%    glmFolder        <str> name of the glm output folder. Default is 
%                      'glm-group'.
%    statName         <str> name of the statistics [contrast] folder.
%                      Default is 'osgm'.
%    sumFn            <str> name of the summary file. Default is 
%                      'perm.th30.abs.sig.cluster.summary'.
%    funcDir          <str> path to the functional folder. Default is 
%                      '$FUNCTIONALS_DIR'.
%
% Output:
%    sumTable         <table> a table of of the information in the sumamry
%                      files.
%
% Created by Haiyang Jin (15-Apr-2020)

if ischar(anaList); anaList = {anaList}; end

if ~exist('funcDir', 'var') || isempty(funcDir)
    funcDir = getenv('FUNCTIONALS_DIR');
end

if ~exist('conList', 'var') || isempty(conList)
    % use all contrasts in the analysis folders
    conList = fs_ana2con(anaList, funcDir);
elseif ischar(conList)
    conList = {conList}; 
end

if ~exist('glmFolder', 'var') || isempty(glmFolder)
    glmFolder = 'glm-group';
end

if ~exist('statName', 'var') || isempty(statName)
    statName = 'osgm';
end

if ~exist('sumFn', 'var') || isempty(sumFn)
    sumFn = 'perm.th30.abs.sig.cluster.summary';
end

% all the possible combinations between anaList and conList
[anaTemp, conTemp] = ndgrid(anaList, conList);

% paths to the summary file
sumFile = fullfile(funcDir, groupName, anaTemp(:), conTemp(:), glmFolder, statName, sumFn);

% read all the summary files
sumTCell = cellfun(@(x) fs_readsummary(x, 1), sumFile, 'uni', false);

% row numbers of each summary data table
numRows = cellfun(@(x) size(x, 1), sumTCell);

% create the analysis and contrast lists for sumTable
analysis = arrayfun(@(x, y) repmat(x, y, 1), anaTemp(:), numRows, 'uni', false);
contrast = arrayfun(@(x, y) repmat(x, y, 1), conTemp(:), numRows, 'uni', false);

% make these variables to a column
Group = repmat({groupName}, sum(numRows), 1);
Analysis = vertcat(analysis{:});
Contrast = vertcat(contrast{:});

% combine all tables together
sumTable = horzcat(table(Group, Analysis, Contrast), vertcat(sumTCell{:}));

end