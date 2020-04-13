function [anaStruct, fscmd] = fs_isxconcat(sessid, anaList, conList, outFolder, runcmd)
% [anaStruct, fscmd] = fs_isxconcat(sessid, anaList, conList, [outFolder='group', runcmd = 1])
%
% This function gathers the first-level results from different participant 
% together (via isxconcat-sess). [The first step in group analysis].
% Please make sure to run this command in funcPath ($FUNCTIONALS_DIR).
%
% Inputs:
%    sessid          <string> the filename of the session id file.
%    anaList         <cell of string> a list of the analysis names. OR
%                    <structure> a structure obtained from fs_mkcontrast.m,
%                     which contains both analysis and contrast names.
%    conList         <cell of string> a list of the contrast names. [If
%                     anaList is a structure, conList can be empty.]
%    outFolder       <string> the name of the output (group) folder.
%    runcmd          <logical> do not run the fscmd and only make the
%                     FreeSurfer commands. 1: run fscmd (default); 0: do
%                     not run fscmd.
%
% Output:
%    anaStruct       <struct> a struct includes all analysis, contrast, and
%                     group names.
%    fscmd           <cell of string> The first column is FreeSurfer 
%                     commands used in the current session. And the second 
%                     column is whether the command successed. 
%                     [0: successed; other numbers: failed.] 
%
% Created by Haiyang Jin (12-Apr-2020)

if ~exist('outFolder', 'var') || isempty(outFolder)
    outFolder = 'group';
end

if ~exist('runcmd', 'var') || isempty(runcmd)
    runcmd = 1;
end

% obtain the analysis and contrast lists
if isstruct(anaList)
   anaStruct = anaList;

else
    % convert to cell if necessary 
    if ischar(anaList); anaList = {anaList}; end
    if ischar(conList); conList = {conList}; end
    
    % create all the possible combinations
    [analysisName, contrastName] = ndgrid(anaList, conList);
    
    % create the strucutre to save analysis and contrast names
    anaStruct = struct('analysisName', analysisName(:), 'contrastName', contrastName(:));
end

% add group folder name to the structure
tempStr = repmat({outFolder}, numel(anaStruct), 1);
[anaStruct.group] = tempStr{:};

% "Isxconcat-sess" stands for "intersubject concatentation." 
% create strings for all commands
fscmd = arrayfun(@(x) sprintf(['isxconcat-sess -sf %s -analysis %s '...
    '-contrast %s -o %s'], sessid, anaStruct(x).analysisName, ...
    anaStruct(x).contrastName, outFolder), 1:numel(anaStruct), 'uni', false);

% return if do not run fscmd
if ~runcmd; return; end

% run the command
isnotok = cellfun(@system, fscmd);
if any(isnotok)
    warning('Some FreeSurfer commands (isxconcat-sess) failed.');
end

% make the fscmd one column
fscmd = [fscmd; num2cell(isnotok)]';

end