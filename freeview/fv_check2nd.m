function fv_check2nd(overlayFile)
% fv_check2nd(overlayFile)
%
% This function displays the results of the second-level analysis
% (group-level analysis).
%
% Input:
%     overlayFile        <string> the overlay file to be displayed (have 
%                          to be in the group analysis folder). [If empty,
%                          a GUI will open for selecting the overlay file.]
%
% Output:
%     display the overlay file on the ?h.inflated barin in Freeview.
%
% Created by Haiyang Jin (13-Apr-2020)

if nargin < 1 || isempty(overlayFile)
    % set the default folder is FUNCTIONALS_DIR if it is not empty
    funcDir = getenv('FUNCTIONALS_DIR');
    if isempty(funcDir)
        startDir = pwd;
    else
        startDir = funcDir;
    end
    
    [theFn, thePath] = uigetfile({fullfile(startDir, '*.sig.cluster.nii.gz')}', ...
        ['Please select the overlay file(s) [for results of the second-'...
        'level analysis] you want to display'],...
        'MultiSelect', 'off');
    
else
    tempdir = dir(overlayFile);
    assert(~isempty(tempdir), 'Cannot find the overlay file: %s.', overlayFile);
    
    thePath = tempdir.folder;
    theFn = tempdir.name;
    
end
% the overlay file with full path
theOverlay = fullfile(thePath, theFn);

% find the corresponding annotation file
tempFns = regexp(theFn, '\W+.');
dirAnnot = dir(fullfile(thePath, [theFn(1:tempFns(4)-1) '*.annot']));
theAnnot = fullfile(thePath, dirAnnot.name);

% the surf/ folder in $SUBJECTS_DIR
surfPath = fullfile(getenv('SUBJECTS_DIR'), 'fsaverage', 'surf', filesep);

% hemi 
hemi = fs_2template(thePath, {'lh', 'rh'});

% ?h.aparc.annot file
aparcFile = fullfile(surfPath, '..', 'label', sprintf('%s.aparc.annot', hemi));
fscmd = sprintf(['freeview -f %1$s%2$s.inflated:curvature=%1$s%2$s.curv' ...
    ':annot=%3$s:edgethickness=0:annot_outline=1'...
    ':annot=%4$s:edgethickness=0:annot_outline=1'...
    ':overlay=%5$s:overlay_threshold=1.3,3'...
    ' -viewport 3d &'], surfPath, hemi, aparcFile, theAnnot, theOverlay);

system(fscmd);

end