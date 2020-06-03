function labelFile = fs_cvn_drawlabel(sessCode, anaName, conName, varargin)
% labelFile = fs_cvn_drawlabel(sessCode, anaName, conName, varargin)
%
% This function draws labels with fs_cvn_lookup.m. 
% 
% Inputs:
%    sessCode       <string> session code in $FUNCTIONALS_DIR;
%                   <cell of string> cell of session codes in
%                    %SUBJECTS_DIR.
%    anaName        <string> or <a cell of strings> the names of the
%                    analysis (i.e., the names of the analysis folders).
%    conName        <string> contrast name used glm (i.e., the names of
%                    contrast folders).
%
% Optional (varargin):
%    'viewIdx'      <numeric> the viewpoint index. Please check
%                    fs_cvn_lookup.m for more information.
%    'fthresh'      <numeric> significance level (default is 1.3 (.05)).
%    'extraStr'     <string> extra label information added to the end
%                    of the label name.
%    'reflabel'     <string> reference labels. Default is ''.
%    'ncluster'     <integer> expected number of clusters.
%    'extraopt'     <cell> extra options used in fs_cvn_lookup.m.
%
% Output:
%    labelFile      <string> full filename of the label file.
%
% Created by Haiyang Jin (2-Jun-2020)

%% Deal with inputs
defaultOpts = struct(...
    'viewidx', 3, ...
    'fthresh', 1.3, ...
    'extrastr', 'manual', ...
    'reflabel', '', ...
    'ncluster', 1, ...
    'extraopt', {{}} ...
    );

opts = fs_mergestruct(defaultOpts, varargin);

viewIdx = opts.viewidx;
fthresh = opts.fthresh;
extraLabelStr = opts.extrastr;
refLabel = opts.reflabel;
nCluster = opts.ncluster;
extraopt = opts.extraopt;

if ~endsWith(extraLabelStr, '.')
    extraLabelStr = [extraLabelStr '.'];
end

% subject information
hemi = fs_2hemi(anaName);
template = fs_2template(anaName, '', 'self');
subjCode = fs_subjcode(sessCode);
trgSubj = fs_trgsubj(subjCode, template);

% surface functional data
sigFile = fullfile(getenv('FUNCTIONALS_DIR'), sessCode, 'bold', anaName, ...
    conName, 'sig.nii.gz');
surfData = fs_readfunc(sigFile);
valstruct = fs_cvn_valstruct(surfData, hemi);

% reference label
hemiLabel = fs_2hemi(refLabel);
if ~strcmp(hemiLabel, hemi)
    refLabel = strrep(refLabel, hemiLabel, hemi);
end
roiMask = fs_label2mask(refLabel, subjCode, numel(surfData));

% display the figure
extraopt = [{'thresh', fthresh * 1i, 'roimask', roiMask}, extraopt{:}];
[~,Lookup,~,himg] = fs_cvn_lookup(trgSubj,viewIdx,valstruct,'',extraopt{:});

try
    %%%%%%%%%%%%%%%%%%%%%%%% manually draw ROI %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Note: drawroipoly.m is valid only on spherical surfaces.
    roimask = drawroipoly(himg,Lookup);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
catch
    labelFile = '';
    return;
end

% save vertex indices and values
labelMat(:, 1) = 1:numel(roimask);
labelMat(:, 5) = surfData;

% read ?h.white and obtain the coordinates
coord = fs_readsurf([hemi '.white'], subjCode);
labelMat(:, 2:4) = coord;

% apply the mask
labelMat(~roimask, :) = [];

% check the cluster numbers in lable matrix
[~, nLabelClu] = fs_clusterlabel(labelMat, subjCode, fthresh, hemi);
if nLabelClu ~= nCluster
    warning('There are %d clusters in the label (not %d).', nLabelClu, nCluster);
end
% isTheLabel = ismember(clusterIdx, 1:nCluster);
% % remove vertices for other clusters
% labelMat(~isTheLabel, :) = [];

%% Save the label
% make label file name
labelFn = sprintf('roi.%s.f%d.%s.%slabel', hemi, fthresh*10, conName, extraLabelStr);

% make the label
labelFile = fs_mklabel(labelMat, subjCode, labelFn, 'white');

end