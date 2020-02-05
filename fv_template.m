function fscmd = fv_template(hemi, surfType, subjCode)
% This function displays the brain with 'tksurfer'. By default, the
% fsaverage will be displayed and it is helpful for (roughly) checking the
% Talairach coordinates. 
%
% Inputs:
%     hemi          <string> 'lh' or 'rh'
%     surfType      <string> 'inflated', 'white', 'pial'
%     subjCode      <string> the subject code in $SUBJECTS_DIR. 'fsaverage'
%                   by default.
% 
% Output:
%     fscmd         the strings of the FreeSurfer commands.
%     And a window to display the brain....
%
% Created by Haiyang Jin (5-Feb-2020)

if nargin < 1 || isempty(hemi)
    hemi = 'lh';
end

if nargin < 2 || isempty(surfType)
    surfType = 'inflated';
end

if nargin < 3 || isempty(subjCode)
    subjCode = 'fsaverage';
end

% create the commands
fscmd = sprintf('tksurfer %s %s %s -aparc -gray', subjCode, hemi, surfType);
system(fscmd);

end