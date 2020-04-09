function output = fs_checkreg(sessList, isSort, funcPath)
% output = fs_checkreg(sessList, isSort, funcPath)
% 
% This function check the co-registration conducted by preproc-sess.
%
% Inputs:
%    sessList          <string> or <a cell of strings> session codes.
%    isSort            <logical> sort the results by the quality (last
%                       column). 0: do not sort (default); 1: sort the
%                       quality by 'descend'; 2: sort the quality by
%                       'ascend'. 
%    funcPath          <string> the full path to the functional folder.
%
% Output:
%    output            a cell of registration quality if isSort is true.
%                      Otherwise output is empty.
%
% Created by Haiyang Jin (26-Jan-2020)

if nargin < 2 || isempty(isSort)
    isSort = 0;
elseif isSort == 1
    order = 'descend';
elseif isSort == 2
    order = 'ascend';
end

if nargin < 3 || isempty(funcPath)
    funcPath = getenv('FUNCTIONALS_DIR');
end

% creat the commands for checking co-registration
wdBackup = pwd;
cd(funcPath);

fscmd = cellfun(@(x) sprintf('tkregister-sess -s %s -fsd bold -per-run -bbr-sum',...
    x), sessList, 'uni', false);

if isSort
    % run cmds and save the results
    [isok, cmdOutput] = cellfun(@system, fscmd, 'uni', false);
    
    % make sure the commands were performed successfully
    assert(all(~[isok{:}]), 'The ''tkregisgter-sess'' failed for some sessions.');
    
    %% sort out the results
    % replace ? with space
    tempOutput = cellfun(@(x) strrep(x, '?', ' '), cmdOutput, 'uni', false);
    
    % split a row of strings into multiple strings
    tempStrings = cellfun(@split, tempOutput, 'uni', false);

    % combine all cells
    strings = horzcat(tempStrings{:});
    
    % reshape the strings
    output = reshape(strings(1: end-1, :), 3, [])';
    
    % order the output
    output = sortrows(output, 3, order); 
    
else
    % only run the cmds but donot save anything
    output = '';
    cellfun(@system, fscmd);
end

% fprintf('Please do the registration manually if any number is larger than 0.8.\n');
cd(wdBackup);
end