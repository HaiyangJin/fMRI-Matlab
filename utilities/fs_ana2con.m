function [conList, conStruct] = fs_ana2con(anaList, funcPath)
% [conList, conStruct] = fs_ana2con(anaList, funcPath)
%
% This funciton read the contrast names within the analysis folders.
%
% Inputs:
%    anaList           <cell string> list of analysis names.
%    funcPath          <string> path to functional folder
%                       ($FUNCTIONALS_DIR).
%
% Output:
%    conList           <cell string> list of contrast names.
%    conStruct         <struct> contains the information of analysis 
%                       (analysisName) and contrast (contrastName) names. 
%
% Created by Haiyang Jin (16-Apr-2020)

if ischar(anaList); anaList = {anaList}; end

if ~exist('funcPath', 'var') || isempty(funcPath)
    funcPath = getenv('FUNCTIONALS_DIR');
end

%% Find unique contrast names
% find all the *.mat files
matFiles = fullfile(funcPath, anaList, '*.mat');
dirCell = cellfun(@dir, matFiles, 'uni', false);
conDir = vertcat(dirCell{:});

% remove .mat and find the unique contrast names
conNames = cellfun(@(x) erase(x, '.mat'), {conDir.name}, 'uni', false)';
conList = unique(conNames);

assert(~isempty(conList), 'Cannot find any contrast within %s.\n', anaList{:});

%% Create conStruct 
% repeat anlysis names to match the number of contrasts
numCons = cellfun(@numel, dirCell);
anaNames = arrayfun(@(x, y) repmat(x, y, 1), anaList, numCons, 'uni', false);

% create cell to save analysis and contrast names
anaconCell = horzcat(vertcat(anaNames{:}), conNames);
% convert to struct
conStruct = cell2struct(anaconCell, {'analysisName', 'contrastName'}, 2);

end