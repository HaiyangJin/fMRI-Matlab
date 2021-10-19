function [corMask, nCorMask] = fs_cortexmask(subjCode, hemi, struPath)
% [corMask, nCorMask] = fs_cortexmask([subjCode = 'fsaverage', hemi = 'lh', struPath])
%
% This function load ?h.cortex.label and output the vertex indices as the
% mask for surfaces. 
%
% Inputs:
%    subjCode         <string> subject code in $SUBJECTS_DIR.
%    hemi             <string> 'lh' or 'rh'.
%    struPath         <string> full path to the subject folder
%                      ($SUBJECTS_DIR).
%
% Outputs:
%    corMask          <numeric vector> a vector of the vertex indices.
%    nCorMask         <integer> number of vertices in the mask. 
%
% Created by Haiyang Jin

if nargin < 1 || isempty(subjCode)
    subjCode = 'fsaverage';
end

if nargin < 2 || isempty(hemi)
    hemi = 'lh';
end
% sanity check
if ~ismember(hemi, {'lh', 'rh'})
    error('''hemi'' has to be ''lh'' or ''rh'' (not %s).', hemi);
end

if nargin < 3 || isempty(struPath)
    struPath = getenv('SUBJECTS_DIR');
end

% path and filename of the label file
labelFn = sprintf('%s.cortex.label', hemi);

% load the label information
labelData = fs_readlabel(labelFn, subjCode, struPath);

% outputs
corMask = labelData(:, 1);
nCorMask = numel(corMask);

end