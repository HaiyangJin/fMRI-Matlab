function status = fs_mkdir(thedir)
% status = fs_mkdir(thedir)
%
% Make dir(s) if it does not exist.
%
% Input:
%    thedir      <string> or <cell string> a list of directories. 
% 
% Output:
%    status      <logical> Folder creation status indicating whether the 
%                 attempt to create the folder is successful, returned as 0
%                 or 1. Same as 'status' for mkdir.
%
% Created by Haiyang Jin (14-Oct-2020)
%
% See also:
% fs_fullfile

if ischar(thedir); thedir = {thedir}; end

status = cellfun(@makedir, thedir);

end

function status = makedir(thedir)
% make dir if it does not exist
if ~exist(thedir, 'dir')
    status = mkdir(thedir);
else
    status = true;
end

end