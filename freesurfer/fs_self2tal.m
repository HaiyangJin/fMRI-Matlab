function outpoints = fs_self2tal(inpoints, subjCode)
% outpoints = fs_self2tal(inpoints, subjCode)
%
% This function converts self RAS to Talairach coordinates. But the output
% is not exactly he Talairach coordinates, see:
% (https://surfer.nmr.mgh.harvard.edu/fswiki/CoordinateSystems).
%
% In TkSurfer:
%    Vertex Talairach = fs_self2tal(Vertex RAS, subjCode);
%    [vertex RAS should be the coordiantes on ?h.orig]
% In TkMedit:
%    Volume Talairach = fs_self2tal(Volume RAS, subjcode);
%
% Inputs:
%    inpoints        <num array> RAS on self surface [real world].
%    subjCode        <str> subject code in $SUBJECTS_DIR.
%    
% Output:
%    outpoints       <num array> cooridnates in Talairach space. 
%
% Created by Haiyang Jin (13-Nov-2019)
%
% See also:
% fs_self2mni; tal2mni

if ~exist('subjCode', 'var') || isempty(subjCode)
    error('Please input the subject code.');
end

% from Vertex RAS (or Volume RAS) to MNI305 RAS (fsaverage or MNI Talairach)
outpoints1 = fs_self2fsavg(inpoints, subjCode);

% from MNI305 RAS (fsaverage or MNI Talairach) to Talairach
outpoints = mni2tal(outpoints1);

end