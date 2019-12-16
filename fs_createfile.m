function fs_createfile(file, contents)
% This function creates new files for FreeSurfer (e.g, sessid, subjectname,
% runfile).
%
% Inputs:
%    file        the filename with path to be created
%    contents    the contents to be saved (only 1 string)
% Output:
%    a new file is created.
%
% Created by Haiyang Jin (16/12/2019)

fid = fopen(file, 'w');
fprintf(fid, contents);
fclose(fid);

end