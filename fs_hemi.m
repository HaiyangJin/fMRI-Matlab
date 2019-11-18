function hemi = fs_hemi(filename)
% This function determine the hemisphere based on the filename
%
% Created by Haiyang Jin (18/11/2019)

if contains(filename, 'lh')
    hemi = 'lh';
elseif contains(filename, 'rh')
    hemi = 'rh';
else
    hemi = '';
    warning('Cannot determine if this file is for left or right hemisphere.');
end

end