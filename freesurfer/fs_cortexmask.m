function [corMask, nCorMask] = fs_cortexmask(subjCode, hemi, struDir)
% [corMask, nCorMask] = fs_cortexmask([subjCode = 'fsaverage', hemi = 'lh', struDir])
%
% This function load ?h.cortex.label and output the vertex indices as the
% mask for surfaces. 
%
% Inputs:
%    subjCode         <str> subject code in $SUBJECTS_DIR.
%    hemi             <str> 'lh' or 'rh'.
%    struDir          <str> full path to the subject folder ($SUBJECTS_DIR).
%
% Outputs:
%    corMask          <num vec> a vector of the vertex indices.
%    nCorMask         <int> number of vertices in the mask. 
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

if nargin < 3 || isempty(struDir)
    struDir = getenv('SUBJECTS_DIR');
end

% path and filename of the label file
labelFn = sprintf('%s.cortex.label', hemi);

% load the label information
labelData = fs_readlabel(labelFn, subjCode, struDir);

% outputs
corMask = labelData(:, 1);
nCorMask = numel(corMask);

end