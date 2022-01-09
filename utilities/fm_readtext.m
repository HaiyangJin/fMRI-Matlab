function content = fm_readtext(filename, tostr)
% content = fm_readtext(filename, tostr)
% 
% This function reads the text files and output a cell of strings. [The 
% output will be converted to strings if possible.] This function can read
% following files (at least):
%     subjectname;
%     sessid;
%     run_loc.txt; run_main.txt;
%
% Input:
%     filename      <string> the full filename (with path) of the
%                    to-be-read file.
%
% Output:
%     content       <cell of strings> it will be converted to strings if
%                    possible (when there is only one string in that cell).
%
% Created by Haiyang Jin (7-April-2020)

if ~exist('tostr', 'var') || isempty(tostr)
    tostr = 0;
end

% open the file
fid = fopen(filename, 'r');
if fid == -1
  error('Cannot open file for reading: %s', filename);
end

% read the file for each row separately
% (copied from https://www.mathworks.com/matlabcentral/answers/251093-how-do-you-read-a-text-file-into-a-cell-string)
contentC = textscan(fid, '%s', 'delimiter', '\n', 'whitespace', '');
fclose(fid);
contentR  = contentC{1};

% split each row by spaces (delimiter)
contents = cellfun(@(x) split(x, {' ', ','}), contentR, 'uni', false);
% reformat
content = horzcat(contents{:})';

% convert the output to string if possible
if numel(content) == 1 && tostr
    content = content{1};
end

end