function hemiFnList = fs_addhemi(filenames, isHemiFirst)
% This function add '?h' to the filenames. 
% 
% Inputs:
%     filenames       <string> or <a cell of strings> the filenames to be 
%                     put together with '?h'.
%     isHemiFirst     <logical> 1:'?h' is added before filenames; 0: '?h'
%                     is added after filenames.
%
% Output:
%     hemiFnList      a cell of all the output filenames
%
% Created by Haiyang Jin (29-Jan-2020)

% convert the filenames to cell if it is string
if ischar(filenames)
    filenames = {filenames};
end

if nargin < 2 || isempty(isHemiFirst)
    isHemiFirst = 1;
end


hemis = {'lh', 'rh'};

[tempHemi, tempFn] = ndgrid(hemis, filenames);

if isHemiFirst
    first = tempHemi(:);
    second = tempFn(:);
else
    first = tempFn(:);
    second = tempHemi(:);
end

% combine strings
hemiFnList = cellfun(@(x,y) sprintf('%s.%s', x, y), first, second, 'uni', false);