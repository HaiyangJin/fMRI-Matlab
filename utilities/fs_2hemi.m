function hemi = fs_2hemi(filename)
% hemi = fs_2hemi(filename)
%
% This function determine the hemisphere based on the filename
%
% Input:
%    filename       <string> filename to be checked.
%
% Output:
%    hemi           <string> the hemi information.
%
% Created by Haiyang Jin (18-Nov-2019)

if contains(filename, filesep)
    [~, fn, ext] = fileparts(filename);
    filename = [fn, ext];
end

if contains(filename, 'lh')
    hemi = 'lh';
elseif contains(filename, 'rh')
    hemi = 'rh';
else
    hemi = '';
    warning('Cannot determine if this file is for left or right hemisphere.');
end

end