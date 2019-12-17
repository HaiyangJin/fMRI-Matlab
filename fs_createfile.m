function file = fs_createfile(file, contents4save)
% This function creates new files for FreeSurfer (e.g, sessid, subjectname,
% runfile).
%
% Inputs:
%    file        the filename with path to be created
%    contents    the contents to be saved (could be a cell or a string)
% Output:
%    a new file is created.
%
% Created by Haiyang Jin (16/12/2019)

if ischar(contents4save)
    contents4save = {contents4save};
end

% size of the contents to be saved
[nRow, nColu] = size(contents4save);

% open a new file
fid = fopen(file, 'w');

% create the array
rowFormat = ['%s' repmat(' %s', 1, nColu-1)];

allFormat = [rowFormat repmat(['\n' rowFormat], 1, nRow-1)];

transcontent = contents4save';

fprintf(fid, sprintf(allFormat, transcontent{:}));

fclose(fid);

end