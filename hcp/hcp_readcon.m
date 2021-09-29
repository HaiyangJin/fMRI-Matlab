function [conList, conMat] = hcp_readcon(filename)
% [conList, conMat] = hcp_readcon(filename)
%
% Load contrast names and the contrast matrix from the design.con file
% (within *.feat folder).
%
% Inputs:
%    filename       <string> filename of the contrast (design.con) file.
%
% Outputs:
%    conList        <cell str> cell string list of contrasts names.
%    conMat         <double matrix> the contrast matrix (contrast *
%                    [condition + confounds].
%
% Created by Haiyang Jin (2021-09-28)

% open the file
fid = fopen(filename, 'r');
if fid == -1
    error('Cannot open file fpr reading: %s', filename);
end

contentC = textscan(fid, '%s', 'delimiter', '\n', 'whitespace', '');
fclose(fid);
contentR  = contentC{1};

% get contrast names
isCon = cellfun(@(x) contains(x, '/ContrastName'), contentR);
conIdx = cellfun(@(x) regexp(x, '\s')+1, contentR(isCon), 'uni', false);
conList = cellfun(@(x, y) x(y(1): y(2)-2), contentR(isCon), conIdx, 'uni', false);

% get contrast matrix
matIdx = find(cellfun(@(x) contains(x, '/Matrix'), contentR));
tmpCell = cellfun(@split, contentR(matIdx+1:end), 'uni', false);
tmpMat = horzcat(tmpCell{:});
conMat = cellfun(@str2double, tmpMat(1:end-1, :))';

end
