function [conStruct, fscmd] = fs_isxconcat(sessid, anaList, conList, groupFolder, runcmd)
% [conStruct, fscmd] = fs_isxconcat(sessid, anaList, conList, [groupFolder='group', runcmd = 1])
%
% This function gathers the first-level results from different participant 
% together (via isxconcat-sess). [The first step in group analysis].
% Please make sure to run this command in funcPath ($FUNCTIONALS_DIR).
%
% Inputs:
%    sessid          <str> the filename of the session id file.
%    anaList         <cell str> a list of the analysis names. OR
%                 OR <struct> a structure obtained from fs_mkcontrast.m,
%                     which contains both analysis and contrast names.
%    conList         <cell str> a list of the contrast names. [If
%                     anaList is a struct, conList will be ignored; if 
%                     anaList is cell and conList is empty, all the
%                     contrasts in the analysis folders will be used].
%    groupFolder     <str> the name of the output (group) folder.
%    runcmd          <boo> do not run the fscmd and only make the
%                     FreeSurfer commands. 1: run fscmd (default); 0: do
%                     not run fscmd.
%
% Output:
%    conStruct       <struct> a struct includes all analysis, contrast, and
%                     group names.
%    fscmd           <cell str> The first column is FreeSurfer 
%                     commands used in the current session. And the second 
%                     column is whether the command successed. 
%                     [0: successed; other numbers: failed.] 
%
% Created by Haiyang Jin (12-Apr-2020)
%
% See also:
% [fs_selxavg3;] fs_glmfit_osgm

if ~exist('groupFolder', 'var') || isempty(groupFolder)
    groupFolder = 'group';
end

if ~exist('runcmd', 'var') || isempty(runcmd)
    runcmd = 1;
end

% obtain the analysis and contrast lists
if isstruct(anaList)
   conStruct = anaList;

else
    % convert to cell if necessary 
    if ischar(anaList); anaList = {anaList}; end
    
    if ~exist('conList', 'var') || isempty(conList)
        conList = fs_ana2con(anaList);
    elseif ischar(conList)
        conList = {conList}; 
    end
    
    % create all the possible combinations
    [analysisName, contrastName] = ndgrid(anaList, conList);
    
    % create the strucutre to save analysis and contrast names
    conStruct = struct('analysisName', analysisName(:), 'contrastName', contrastName(:));
end

% add group folder name to the structure
tempStr = repmat({groupFolder}, numel(conStruct), 1);
[conStruct.group] = tempStr{:};

% "Isxconcat-sess" stands for "intersubject concatentation." 
% create strings for all commands
fscmd = arrayfun(@(x) sprintf(['isxconcat-sess -sf %s -analysis %s '...
    '-contrast %s -o %s'], sessid, conStruct(x).analysisName, ...
    conStruct(x).contrastName, groupFolder), 1:numel(conStruct), 'uni', false);

if runcmd
    % run FreeSurfer commands
    isnotok = cellfun(@system, fscmd);
else
    % do not run fscmd
    isnotok = zeros(size(fscmd));
end

% make the fscmd one column
fscmd = [fscmd; num2cell(isnotok)]';

if any(isnotok)
    warning('Some FreeSurfer commands (isxconcat-sess) failed.');
elseif runcmd
    fprintf('\nisxconcat-sess finished without error.\n');
end

end