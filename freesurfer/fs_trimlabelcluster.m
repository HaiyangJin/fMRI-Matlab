function fs_trimlabelcluster(labelFn, subjCode, nCluExp)
% fs_trimlabelcluster(labelFn, subjCode, nCluExp)
%
% This function trims the label by clusters. It will only keep the first 
% 'nCluExp' clusters in the 'labelFn'.
%
% Inputs:
%    labelFn        <string> label filename.
%    subjCode       <string> subject code.
%    nCluExp        <integer> number of expected clusters. Default is 1.
%
% Output:
%    a trimmed label.
%
% Created by Haiyang Jin (3-Jun-2020)

if ~exist('nCluExp', 'var') || isempty(nCluExp)
    nCluExp = 1;
end

% read label
labelMat = fs_readlabel(labelFn, subjCode);
% obtain the label-related information
hemi = fm_2hemi(labelFn);
fthresh = fm_2thresh(labelFn);
% convert threshold to numeric
thresh = str2double(fthresh(2:end))/10;

% identify the number of clusters in the label
[cluIdx, nLabelClu] = fs_clusterlabel(labelMat, subjCode, thresh, hemi);

% only keep the first 'nCluExp' if needed
if nLabelClu > nCluExp
    isLabel = ismember(cluIdx, 1:nCluExp);
    
    % remove the extra clusters
    labelMat(~isLabel, :) = [];
    
    % only keep the filename
    [~, thefn, theext] = fileparts(labelFn);
    
    % make the new label
    fs_mklabel(labelMat, subjCode, [thefn theext]);
end

end