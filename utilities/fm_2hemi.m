function hemi = fm_2hemi(filename, fnOnly)
% hemi = fm_2hemi(filename, fnOnly)
%
% This function determine the hemisphere based on the filename
%
% Input:
%    filename       <string> filename to be checked.
%    fnOnly         <logical> 1 [default]: only check the filename; 0:
%                    also check the path.
%
% Output:
%    hemi           <string> the hemi information.
%
% Created by Haiyang Jin (18-Nov-2019)

if ~exist('fnOnly', 'var') || isempty(fnOnly)
    fnOnly = 1;
end

if contains(filename, filesep) && fnOnly
    [~, fn, ext] = fileparts(filename);
    filename = [fn, ext];
end

if contains(filename, {'lh', '.L.'})
    hemi = 'lh';
elseif contains(filename, {'rh', '.R.'})
    hemi = 'rh';
else
    hemi = '';
    warning('Cannot determine if this file is for left or right hemisphere.');
end

end