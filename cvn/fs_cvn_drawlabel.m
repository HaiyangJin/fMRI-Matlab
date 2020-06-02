function labelFile = fs_cvn_drawlabel(sessCode, anaName, conName, fthresh, ...
    extraLabelStr, viewIdx, extraopt)
% labelFile = fs_cvn_drawlabel(sessCode, anaName, conName, fthresh, ...
%    extraLabelStr, viewIdx, extraopt)
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
%    fthresh        <numeric> significance level (default is 2 (.01)).
%    extraLabelStr  <string> extra label information added to the end
%                    of the label name.
%    viewIdx        <numeric> the viewpoint index. Please check
%                    fs_cvn_lookup.m for more information.
%    extraopt       <cell> extra options used in fs_cvn_lookup.m.
%
% Output:
%    labelFile      <string> full filename of the label file.
%
% Created by Haiyang Jin (2-Jun-2020)

if ~exist('fthresh', 'var') || isempty(fthresh)
    fthresh = 1.3; % p < .05
end
if ~exist('extraLabelStr', 'var') || isempty(extraLabelStr)
    extraLabelStr = '';
elseif ~endsWith(extraLabelStr, '.')
    extraLabelStr = [extraLabelStr '.'];
end
if ~exist('viewIdx', 'var') || isempty(viewIdx)
    viewIdx = 3;
end
if ~exist('extraopt', 'var') || isempty(extraopt)
    extraopt = {};
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

% display the figure
extraopt = [{'thresh', fthresh * 1i}, extraopt{:}];
[~,Lookup,~,himg] = fs_cvn_lookup(trgSubj,viewIdx,valstruct,'',extraopt{:});

%%%%%%%%%%%%%%%%%%%%%%%%%%% manually draw ROI %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Note: drawroipoly.m is valid only on spherical surfaces.
roimask = drawroipoly(himg,Lookup);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% save vertex indices and values
data(:, 1) = 1:numel(roimask);
data(:, 5) = surfData;

% read ?h.white and obtain the coordinates
coord = fs_readsurf([hemi '.white'], subjCode);
data(:, 2:4) = coord;

% apply the mask
data(~roimask, :) = [];

% make label file name
labelFn = sprintf('roi.%s.f%d.%s.%slabel', hemi, fthresh*10, conName, extraLabelStr);

% make the label
labelFile = fs_mklabel(data, subjCode, labelFn, 'white');

end