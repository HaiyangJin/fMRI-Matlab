function [allPath, pathCell] = fs_fullfile(varargin)
% allPath = fs_fullfile(varargin)
%
% This function creates the path with all the possible combinations within
% varargin. 
%
% Input:
%    varargin       Different parts of path separated by ','.
% 
% Output:
%    allPath        <cell string> a list of all the paths.
%
% Example:
% thePath = fs_fullfile('main_path', {'subdir1', 'subdir2'}, 'anotherPath');
% thePath is 2x1 cell array.
%     {'main_path/subdir1/anotherPath'}
%     {'main_path/subdir2/anotherPath'}
%
% Created by Haiyang Jin (17-Apr-2020)

%% Make sure not all varargin are full path
isOne = cellfun(@numel, varargin) == 1;
if all(isOne)
    isFilesep = cellfun(@(x) contains(x, filesep), varargin);
else
    isFilesep = false;
end

% copy varargin to allPath if all varargin is a full path
if all(isFilesep)
    allPath = varargin;
    pathCell = {};
    return;
end

%% Combine all the inputs to make the path
pathPart = varargin;

% convert string to cell
isOne = cellfun(@ischar, pathPart);
pathPart(isOne) = cellfun(@(x) {x}, varargin(isOne), 'uni', false);

% create all possible combinations 
pathComb = cell(size(pathPart));
[pathComb{:}] = ndgrid(pathPart{:});

% make strings in each cell to one column
pathCell = cellfun(@(x) x(:), pathComb, 'uni', false);

% create the path
allPath = fullfile(pathCell{:});

end