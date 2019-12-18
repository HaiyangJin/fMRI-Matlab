function [roisize, talCoor, nVtx, VtxMax] = fs_fun_labelsize(projStr, subjCode_bold, ...
    label_fn, output_path, beta_fn, thmin)
% This function obtains the size of the label (ROI) from FreeSurfer
% commands (mri_surfcluster).
%
% Inputs:
%    projStr           matlab structure for the project (obtained from fs_fun_projectinfo)
%                      This is specific for each project.
%    subjCode_bold     subject code for functional data
%    lable_fn          label filename
%    output_path       where the temporary output file is saved
%    beta_fn           based on which data file to obtain the cluster
%    thmin             the minimal threshold (magic number)
% Outputs:
%    roisize           size in mm2
%    talCoor           the talairach coordinates for the peak (maybe)
%    nVtx              number of vertices in this label
%    VtxMax            the vertex number of the peak response
%
% Created by Haiyang Jin (18/11/2019)

if nargin < 4 || isempty(output_path)
    output_path = '.';
end
output_path = fullfile(output_path, 'Label_Size');
if nargin < 5 || isempty(beta_fn)
    beta_fn = 'beta.nii.gz';
end
if ~exist(output_path, 'dir'); mkdir(output_path); end

if nargin < 6 || isempty(thmin)
    thmin = 0.001;
end

% load project information
boldext = projStr.boldext;

hemi = fs_hemi(label_fn);
subjCode = fs_subjcode(subjCode_bold, projStr.funcPath);

% label file
labelfile = fullfile(projStr.subjects, subjCode, 'label', label_fn);

% beta file
analysisfolder = sprintf('loc%s.%s', boldext, hemi);
betafile = fullfile(fullfile(projStr.funcPath, subjCode_bold, ...
        'bold', analysisfolder, beta_fn));

% create the freesurfer command
fn_out = sprintf('cluster%%%s%%%s.txt', label_fn, subjCode);
file_out = fullfile(output_path, fn_out);
fs_command = sprintf(['mri_surfcluster --in %s --clabel %s --subject %s ' ...
    '--surf inflated --thmin %d --hemi %s --sum %s'], ...
    betafile, labelfile, subjCode, ...
    thmin, hemi, file_out);

system(fs_command);

%% load the output file from mri_surfcluster
tempcell = importdata(file_out, ' ', 36);

tempdata = tempcell.data;

VtxMax = tempdata(3);
roisize = tempdata(4);
talCoor = tempdata(5:7);
nVtx = tempdata(8);

end