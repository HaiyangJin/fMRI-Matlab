function isAvailable = fs_checklabel(fn_label, subjCode)
% This function checks if there is the label for this subject
% 
% Created by Haiyang Jin (28/11/2019)

FS = fs_setup;

label_file = fullfile(FS.subjects, subjCode, 'label', fn_label);

isAvailable = exist(label_file, 'file');