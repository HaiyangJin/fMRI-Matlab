function [levelCell, levelNames] = fs_pathinfo2table(pathInfo)
% [levelCell, levelNames] = fs_pathinfo2table(pathInfo)
%
% This function gathers the condition information from the path. ?This
% function is mainly used in fs_readsummary and fs_group_surfcluster).
%
% Inputs:
%    pathInfo        <cell> a 1xQ or Px1 cell. All the path and filename
%                     information to theto-be-printed files. Each row is
%                     one layer (level) ofthe path and all the paths will
%                     be combined in order(with all possible combinations).
%                     [fileInfo will be dealt with fs_fullfile.m]
%
% Output:
%    levelCell       <cell string> the condition levels.
%    levelName       <cell string> the condition names.
%
% Example:
% pathInfo = {'path1', {'path2a', 'path2b'}, {'path3a', 'path3b', 'path3c'}};
% [levelCell, levelNames] = fs_pathinfo2table(pathInfo)
%
% Created by Haiyang Jin (3-Nov-2020)
%
% See also:
% fs_readsummary, fs_group_surfcluster

isMulti = cellfun(@(x) iscell(x) && numel(x) ~= 1, pathInfo);
multiLevels = pathInfo(isMulti);

% repeat the multiple levels for each table
[~, levels] = fs_fullfile(multiLevels{:});
levelCell = [levels{:}];
levelNames = arrayfun(@(x) sprintf('Name%d', x), 1:size(levelCell, 2), 'uni', false);

% infoTableCell = arrayfun(@(x) cell2table(repmat(levelCell(x, :), size(sumTableCell{x}, 1), 1), ...
%     'VariableNames', levelNames), 1: size(levelCell,1), 'uni', false)';

end