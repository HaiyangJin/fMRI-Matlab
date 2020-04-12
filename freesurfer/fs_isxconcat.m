function [fscmd, isnotok] = fs_isxconcat(sessid, anaList, conList, outFolder)
% [fscmd, isnotok] = fs_isxconcat(sessid, anaList, conList, [outFolder='group'])
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
%
% Output:
%    fscmd           <cell of string> FreeSurfer commands used in the
%                     current session.
%    isnotok         <array of numeric> 0: the command successed; other
%                     numbers: the command failed. 
%
% Created by Haiyang Jin (12-Apr-2020)

if nargin < 4 || isempty(outFolder)
    outFolder = 'group';
end

% obtain the analysis and contrast lists
if isstruct(anaList)
    % obtain list from the structure
    analysis = {anaList.analysisName};
    contrast = {anaList.contrastName};
else
    % convert to cell if necessary 
    if ischar(anaList); anaList = {anaList}; end
    if ischar(conList); conList = {conList}; end
    
    % create all the possible combinations
    [analysis, contrast] = ndgrid(anaList, conList);
end

% "Isxconcat-sess" stands for "intersubject concatentation." 
% create strings for all commands
fscmd = cellfun(@(x, y) sprintf(['isxconcat-sess -sf %s -analysis %s '...
    '-contrast %s -o %s'], sessid, x, y, outFolder), analysis, contrast, 'uni', false);

% run the command
isnotok = cellfun(@system, fscmd);
if any(isnotok)
    warning('Some FreeSurfer commands (isxconcat-sess) failed.');
end

% make the fscmd one column
fscmd = fscmd';

end