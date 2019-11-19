function roisize = fs_labelsize(subjCode_bold, labelfn, betafn, thmin)
% This function obtains the size of the label (ROI) from FreeSurfer
% commands (mri_surfcluster).
%
% Created by Haiyang Jin (18/11/2019)

if nargin < 3 || isempty(betafn)
    betafn = 'beta.nii.gz';
end
if nargin < 4 || isempty(thmin)
    thmin = 0.1;
end

% load FreeSurfer set up
FS = fs_setup;

hemi = fs_hemi(labelfn);
subjCode_mri = fw_subjcode(subjCode_bold);

% label file
if labelfn(1) ~= filesep
    labeldir = dir(fullfile(FS.subjects, subjCode_mri, 'label', labelfn));
else
    labeldir = dir(labelfn);
end
labelfile = fullfile(labeldir.folder, labeldir.name);

% beta file
if betafn(1) ~= filesep
    analysisfolder = ['loc_self.' hemi];
    betadir = dir(fullfile(FS.subjects, '..', 'Data_fMRI', subjCode_bold, ...
        'bold', analysisfolder, betafn));
else
    betadir = dir(betafn);
end
betafile = fullfile(betadir.folder, betadir.name);

% create the freesurfer command
tempout = 'tempout';
fs_command = sprintf(['mri_surfcluster --in %s --clabel %s --subject %s ' ...
    '--surf white --thmin %d --hemi %s --sum %s'], ...
    betafile, labelfile, subjCode_mri, ...
    thmin, hemi, tempout);

system(fs_command);

%% load the output file from mri_surfcluster
tempcell = importdata(tempout, ' ', 36);

tempdata = tempcell.data;

roisize = tempdata(4);

% delete the temporary file
delete(tempout);

end