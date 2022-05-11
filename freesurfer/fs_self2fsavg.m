function [outpoints, vtx, esterr] = fs_self2fsavg(inpoints, subjCode, surf)
% [outpoints, vtx, esterr] = fs_self2fsavg(inpoints, subjCode, surf)
%
% This functions converts self surface (or volume) RAS [in real world] to 
% MNI305 (fsaverage) RAS by following 
% https://surfer.nmr.mgh.harvard.edu/fswiki/CoordinateSystems (2).
%
% [It is not the Talairach coordinates shown in tksurfer (surface % or 
% volume). Talairach shown in tksurfer is use fs_self2tal.m] 
%
% In TkSurfer:
%    Vertex MNI Talairach = fs_self2fsavg(Vertex RAS, subjCode);
%    [vertex RAS should be the coordiantes on ?h.orig]
% In TkMedit:
%    MNI Talairach = fs_self2fsavg(Volume RAS, subjCode);
%
% Inputs:
%    inpoints        <num mat> RAS on self surface [real world].
%    subjCode        <str> subject code in $SUBJECTS_DIR.
%    surf            <str> which surface to be used to estimate the vertex
%                     on fsaverage (e.g., 'lh.white'). Default is ''; then 
%                     not estimate the vertex. When hemisphere infor is 
%                     included, please make sure it is not the wrong 
%                     hemisphere. Note if no hemisphere information is 
%                     inclluded in surf, e.g., 'white', both hemispheres
%                     will be loaded to estimate the vertex.
%
% Output:
%    outpoints       <num mat> cooridnates on fsaverage (MNI305 or MNI 
%                     Talairach).
%    vtx             <int> the vertex index on fsaverage. When no hemisphere
%                     is specified, 1-163842 refer to vertices on left 
%                     hemisphere and 163843 and larger numbers refer to
%                     right hemisphere.
%    esterr          <num vec> estiamtion error; i.e., distance between the
%                     outpoints and the corresponding vertices on fsaverage.
%
% Created by Haiyang Jin (13-Nov-2019)
%
% See also:
% fs_self2tal; mni2tal

if nargin < 1
    fprintf('Usage: [outpoints, vtx, esterr] = fs_self2fsavg(inpoints, subjCode, surf);\n');
    return;
end

if ~exist('subjCode', 'var') || isempty(subjCode)
    error('Please input the subject code.');
end

%% Load the TalXFM file for this subject
taldir = fullfile(getenv('SUBJECTS_DIR'), subjCode, 'mri', 'transforms', 'talairach.xfm');
[~, talXFM] = system(sprintf('cat %s', taldir));

% split talXFM
strs = strsplit(talXFM, {' ', ';', '\n'});
strs(cellfun(@isempty, strs)) = [];  % remove empty cells

% convert strings to numeric array
nums = cellfun(@str2double, strs(end-11:end));
talMat =  reshape(nums, 4, 3)';

%% Convert to fsaverage (MNI305) [MNI Talariarch]
% load Torig and Norig
Torig = fs_TNorig(subjCode, 't');
Norig = fs_TNorig(subjCode, 'n');

% converting RAS
inRAS = horzcat(inpoints, ones(size(inpoints, 1), 1))';
outRAS = talMat * Norig / Torig * inRAS;

outpoints = outRAS';

%% Estimate the vertex index if needed
if ~exist('surf', 'var') || isempty(surf)
    vtx = 0;
    esterr = 0;
    return;
end

if ~contains(surf, 'lh') && ~contains(surf, 'rh')
    lhc = fs_readsurf(['lh.' surf], subjCode);
    rhc = fs_readsurf(['rh.' surf], subjCode);
    c = [lhc; rhc];
else
    c = fs_readsurf(surf);
end

% euclidean
Ds = pdist2(c, outpoints);
% which vertex
[esterr, vtx] = min(Ds);

end