function fscmd = fv_template(hemi, surfType, annot, subjCode)
% This function displays the brain with 'tksurfer'. By default, the
% fsaverage will be displayed and it is helpful for (roughly) checking the
% Talairach coordinates. 
%
% Inputs:
%     hemi          <string> 'lh' or 'rh';
%     surfType      <string> 'inflated', 'white', 'pial';
%     annot         <string> or <numeric> strings for the annotation file
%                   or numeric 1 uses '-aparc' and 2 uses '-a2009s';
%     subjCode      <string> the subject code in $SUBJECTS_DIR. 'fsaverage'
%                   by default.
% 
% Output:
%     fscmd         the strings of the FreeSurfer commands.
%     And a window (FreeSurfer 5.3) to display the brain....
%
% Created by Haiyang Jin (5-Feb-2020)

if nargin < 1 || isempty(hemi)
    hemi = 'lh';
end

if nargin < 2 || isempty(surfType)
    surfType = 'inflated';
end

if nargin < 3 || isempty(annot)
    annot = 1;
end
if isnumeric(annot)
    switch annot
        case 1
            annot = ' -aparc';
        case 2
            annot = ' -a2009s';
    end
end

if nargin < 4 || isempty(subjCode)
    subjCode = 'fsaverage';
end

% create the commands
fscmd = sprintf('tksurfer %s %s %s %s -gray', subjCode, hemi, surfType, annot);
system(fscmd);

end