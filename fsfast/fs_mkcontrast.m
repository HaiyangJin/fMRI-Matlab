function [conStruct, fscmd] = fs_mkcontrast(anaList, conditions, contrasts, method, runcmd)
% [conStruct, fscmd] = fs_mkcontrast(anaList, conditions, contrasts, ...
%                      [method=1, runcmd=1])
%
% This function creates contrast and run mkcontrast-sess in FreeSurfer.
% IMPORTANT: Please make sure the order of levels in 'condtions' is the
% same as that in the *.par (paradigm) file. [fs_par2con can be used to
% obtain the conditions.]
%
% Inputs:
%    anaList           <cell str> a list of all analysis names;
%    conditions        <cell str> the full names of all conditions;
%                       [conditions can be obtained from fs_par2cond.m]
%    contrasts         <cell> a cell of contrasts to be created. One row
%                       is one contrast; the conditions in the first cell
%                       is the activation condition; the conditions in the
%                       second cell is the control condition. 
%                      [If multiple levels need to be used for the 
%                       activation or control conditions, put the multiple
%                       levels in one cell.]
%                      [use 'base' in the second cell if you want to
%                       contrast the activation conditons against the baseline; 
%                       if the second cell is ''(without space), all the
%                       conditions will be used as the control condition]
%                      [IMPORTANT: you may want to check 'method' below if
%                       you want to use initials of conditions in the
%                       contrast names (e.g., 'f' for 'faces'; 'w' for
%                       'wrods').]
%                       Default is all pairs. 
%    method            <int> which method (function) to be used identify 
%                       the condition number for each contrasts. More see
%                       below.
%    runcmd            <boo> whether run the fscmd in FreeSufer (i.e.,
%                       make contrasts in FreeSurfer). 1: run fscmd
%                       [default]; 0: do not run fscmds and only output
%                       conStruct and fscmd.
%
% Output:
%    conStruct         <struct> a contrast structure which has three
%                       fieldnames. (analysisName: the ananlysis name;
%                       contrastName: the contrast name in format of a=vs=b;
%                       contrastCode: the commands to be used in FreeSurfer).
%                       conStruct will also be saved as the Matlab
%                       file and its name will be the initials of all the
%                       conditions.
%    fscmd             <cell str> FreeSurfer commands run in the
%                       current session.
%
%%%%%%%%%%%%%%%%%%%% Methods %%%%%%%%%%%%%%%%%%%%
% % avaiable functions to identify condition numbers for contrasts (from conditions) 
% methodFuncs = {
%     @startsWith;  % 1: when contrasts match beginning of condtion names.
%     @endsWith;    % 2: when contrasts match ending of condtion names.
%     @contains;    % 3: when contrasts are contained in condtion names.
%     @strcmp;      % 4: only when contrasts match condition names (case sensitive)
%     @strcmpi;     % 5: only when contrasts match condition names (case insensitive).
%     };
% % 4 and 5 are not applicable when multiple levels are used as activation or
% % control condtions.
%
% Example:
% anaList = {'main_sm5.lh', 'main_sm5.rh'}; % [obtained from fs_mkanalysis.m]
% contrasts = {
%     'face1', 'base';
%     'face', 'object';
%     'fa', 'obj';
%     'face2', {'object', 'word'};
%     {'o', 'w'}, 'f';
%     {'f', 'o', 'w'}, ''};
% conditions = {
%     'face1';
%     'face2';
%     'word';
%     'object'}; % can be obtained from fs_par2cond.m.
% method = 1;  % startsWith
% conStruct = fs_mkcontrast(anaList, conditions, contrasts, method, 0);
%
% Outputs of this example:
% Contrast names and codes are:
%     'face1=vs=baseline'       ' -a 1'                                       'startsWith'
%     'face=vs=object'          ' -a 1 -a 2 -c 4'                             'startsWith'
%     'fa=vs=obj'               ' -a 1 -a 2 -c 4'                             'startsWith'
%     'face2=vs=object-word'    ' -a 2 -c 3 -c 4'                             'startsWith'
%     'o+w=vs=f'                ' -a 3 -a 4 -c 1 -c 2'                        'startsWith'
%     'f+o+w=vs=all'            ' -a 1 -a 2 -a 3 -a 4 -c 1 -c 2 -c 3 -c 4'    'startsWith'
%
% Created by Haiyang Jin (2019-Dec-19)
%
% See also:
% [fs_mkanalysis;] fs_selxavg3

%% Deal with inputs

if nargin < 1
    fprintf('Usage: [conStruct, fscmd] = fs_mkcontrast(anaList, conditions, contrasts, method, runcmd);\n');
    return;
elseif ischar(anaList)
    anaList = {anaList}; 
else
    anaList = anaList(:);
end
nAnalysis = numel(anaList);

if ~exist('contrasts', 'var') || isempty(contrasts)
    % use all pairs in conditions as default
    nCond = numel(conditions);
    comb = nchoosek(1:nCond, 2);
    contrasts = conditions(comb);
end
nContrast = size(contrasts, 1);

if ~exist('method', 'var') || isempty(method)
    method = ones(nContrast, 1);
elseif numel(method) == 1
    method = repmat(method, nContrast, 1);
elseif numel(method) ~= nContrast
    error(['The length of ''method'' (%d) has to be 1 or the same number ' ...
        'of contrasts (%d).'], numel(method), nContrast);
end

isAva = method <= 5 & method >0;
assert(all(isAva), 'No function is pre-defined for the method (%d).', method(~isAva));

% avaiable functions to identify condition numbers for contrasts (from conditions) 
methodFuncs = {
    @startsWith;  % 1: when contrasts match beginning of condtion names.
    @endsWith;    % 2: when contrasts match ending of condtion names.
    @contains;    % 3: when contrasts are contained in condtion names.
    @strcmp;      % 4: only when contrasts match condition names (case sensitive)
    @strcmpi;     % 5: only when contrasts match condition names (case insensitive).
    };
% 4 and 5 are not applicable when multiple levels are used as activation or
% control condtions.
methods = methodFuncs(method);

if ~exist('runcmd', 'var') || isempty(runcmd)
    runcmd = 1;
end

%% Create names and codes for each contrast
% empty cell for saving contrast names, codes and methods
conCell = cell(nContrast, 3);

for iCon = 1:nContrast
        
    % this contrast
    thisCon = contrasts(iCon, :);
    methodFunc = methods{iCon, 1};
    
    % the number of activation and control condition
    conditionNum = cellfun(@(x) find(methodFunc(conditions, x)), thisCon, 'uni', false);
    
    % numbers of levels in activation and control
    nLevels = cellfun(@numel, conditionNum);
    assert(nLevels(1) ~= 0, ['Cannot find the condition number for '...
        'the activation (%d) conditions.'], nLevels(1));
    
    %%%%%%%%%%%% Activation conditions %%%%%%%%%%%%
    if iscell(thisCon{1})
        actCon = thisCon{1};
    else
        actCon = thisCon(1);
    end
    % first part of contrast name
    contrNameAct = sprintf(['%s' repmat('+%s', 1, numel(actCon)-1) '-vs-'], actCon{:});
    % first part of contrast code
    contrCodeAct = sprintf(['-a %d' repmat(' -a %d', 1, nLevels(1)-1)], conditionNum{1});
    
    %%%%%%%%%%%% Control conditions %%%%%%%%%%%%
    if nLevels(2) == 0
        % if there is no control condition [NULL will be used as
        % control condition]
        contrNameCon = 'baseline';
        contrCodeCon = '';
    else
        if iscell(thisCon{2})
            baseCon = thisCon{2};
        else
            baseCon = thisCon(2);
        end
        % second part of contrast name
        contrNameCon = sprintf(['%s' repmat('+%s', 1,numel(baseCon)-1)], baseCon{:});
        if isempty(contrNameCon) && nLevels(2) == numel(conditions)
            contrNameCon = 'all';
        end
        % second part of contrast code
        contrCodeCon = sprintf([' -c %d' repmat(' -c %d', 1, nLevels(2)-1)], conditionNum{2});
    end
    
    %%%%%%%%%%%% Combine activation and control %%%%%%%%%%%%
    conCell{iCon, 1} = [contrNameAct, contrNameCon];
    conCell{iCon, 2} = [contrCodeAct, contrCodeCon];
    conCell{iCon, 3} = func2str(methodFunc);

end  % iCon
    
% display the contrast names and codes
fprintf('Contrast names and codes are:\n');
disp(conCell);

%% Create FreeSurfer commans for creating contrasts
% create all the combinations of analyses and contrasts
[anaTemp, conTemp] = ndgrid(1:nAnalysis, 1:nContrast);

analysisName = anaList(anaTemp(:));
contrastName = conCell(conTemp(:), 1);
contrastCode = conCell(conTemp(:), 2);
contrastMethod = conCell(conTemp(:), 3);

% create FreeSurfer commands
fscmd = arrayfun(@(x) sprintf('mkcontrast-sess -analysis %s -contrast %s %s', ...
    analysisName{x}, contrastName{x}, contrastCode{x}), 1:numel(analysisName), 'uni', false)';

%% Run FreeSurfer commands if needed
[fscmd, isnotok] = fm_runcmd(fscmd, runcmd);

%% Create conStruct including analysis and contrast information
conStruct = table2struct(table(analysisName, contrastName, contrastCode, contrastMethod));

% finishing message
if any(isnotok)
    warning('Some FreeSurfer commands (mkcontrast-sess) failed.');
elseif runcmd
    fprintf('\nmkcontrast-sess finished without error.\n');
end

end