function varargout = fs_readannot(annotFn, subjCode, roiName, struPath, extraopts)
% [rois, roiColors, roiList, nVtxRoi] = fs_readannot([annotFn, subjCode, roiName, struPath, extraopts])
%
% This funciton reads the annotation files and output the binary masks for
% all the parcellations (rois) and their colors.
%
% Inputs:
%    annotFn         <string> filename of the annotation file (with or without
%                     path). If path is included in annotFn, 'subjCode'
%                     and struPath will be ignored. Default is
%                     'lh.aparc.annot'.
%    subjCode        <string> subject code in struPath. Default is
%                     fsaverage.
%    roiName         <cell string> a list of parcellation (roi) names to be
%                     output. Default is all roi names.
%    struPath        <string> $SUBJECTS_DIR.
%    extraopts       <integer> if true (>0), disp running output; if false
%                     (==0), be quiet and do not display any running
%                     output.
%
% Output:
%    rois            <cell logical> a list of binary masks for each
%                     roiName.
%    roiColors       <cell numeric> Px3. RGB color for each roiName.
%    roiList         <cell string> list of roi names in the annotFn file.
%    nVtxRoi         <cell integer> P. number of vertices in each roiName.
%
% Dependency:
%    FreeSurfer Matlab functions.
%
% Created by Haiyang Jin (23-Apr-2020)

if ~exist('annotFn', 'var') || isempty(annotFn)
    annotFn = 'lh.aparc.annot';
    warning('''%s'' is loaded by default.', annotFn);
end
if ~exist('extraopts', 'var') || isempty(extraopts)
    extraopts = 0;
end

% check if the path is available
filepath = fileparts(annotFn);

if isempty(filepath)
    if ~exist('subjCode', 'var') || isempty(subjCode)
        subjCode = 'fsaverage';
        warning('''fsaverage'' is used as ''subjCode'' by default.');
    end
    % use SUBJECTS_DIR as the default subject path
    if ~exist('struPath', 'var') || isempty(struPath)
        struPath = getenv('SUBJECTS_DIR');
    end
    annotFile = fullfile(struPath, subjCode, 'label', annotFn);
else
    % use the label filename directly
    annotFile = annotFn;
end

% make sure the annot file is available
if ~exist(annotFile, 'file')
    % warning('Cannot find the annotation file: %s for %s.', annotFile, subjCode);
    varargout = {{}, {}, {}, []}; 
    return;
end

%% Read and process the annotation file

[vtx, label, ctab] = read_annotation(annotFile, extraopts);
roiList = ctab.struct_names;
nVtx = numel(vtx);

% use all parcellations as roiName by default
if ~exist('roiName', 'var') || isempty(roiName)
    roiName = roiList;
else
    if ischar(roiName); roiName = {roiName}; end
    isAva = ismember(roiName, roiList);
    assert(all(isAva), ['Cannot find some of the roi names in the '...
        'annotation file (%s).'], annotFile);
end

% find vertex indices for each roi
roiIndices = cellfun(@(x) find(strcmp(x, roiList)), roiName);
roiCode = ctab.table(roiIndices, 5);
roiCell = arrayfun(@(x) label == x, roiCode, 'uni', false);

% make binary mask for each roi
[rois, nVtxRoi] = cellfun(@(x) makeroi(nVtx, x), roiCell, 'uni', false);

% save the colors as [0, 1]
roiColors = ctab.table(roiIndices, 1:3)/255;

% save the output
varargout{1} = rois;
varargout{2} = roiColors;
varargout{3} = roiList;
varargout{4} = nVtxRoi;

end

function [maskroi, nVtxRoi] = makeroi(nVtx, vtxInd)
% make binary masks
maskroi = zeros(nVtx, 1);
maskroi(vtxInd) = 1;
nVtxRoi = sum(maskroi);

end