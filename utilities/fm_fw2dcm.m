function fm_fw2dcm(searchDir, trgDirwd, outDir)
% fm_fw2dcm(searchDir, trgDirwd, outDir)
%
% Walk through all the sub-directories, un-zip and copy dicoms files from 
% Flywheel to a (more decent) folder/directory. 
%
% Inputs:
%    searchDir       <str> directory for searching for DICOM files. Default
%                     to current working directory.
%    trgDirwd        <str> wildcard strings for the target folder, which
%                     is the (sub-)folders storing the DICOM files or DICOM
%                     zip files. Default to 'anat*'.
%    outDir          <str> directory to save the DICOM files. Default to a
%                     folder named 'flywheel_dcm' in searchDir.
%
% Created by Haiyang Jin (2023-June-17)

% Deal with inputs
if nargin < 1
    fprintf('fm_fw2dcm(searchDir, trgDirwd, outDir);\n');
end

if ~exist('searchDir', 'var') || isempty(searchDir)
    searchDir = pwd;
else
    tmpdir = dir(fullfile(searchDir, '*'));
    searchDir = tmpdir(1).folder;
end

if ~exist('trgDirwd', 'var') || isempty(trgDirwd)
    trgDirwd = 'anat*';
end

if ~exist('outDir', 'var') || isempty(outDir)
    outDir = fullfile(fileparts(tmpdir(1).folder), 'flywheel_dcm');
end
while exist(outDir, 'dir')
    outDir = [outDir '_dcm']; %#ok<AGROW> 
end

%% Locate all subject and session folders if available
dirList = {searchDir};
while true
    
    % search for the target folder
    [subdirlists, dones] = cellfun(@(x) searchtrg(x, trgDirwd), dirList, 'uni', false);
    
    if all(cell2mat(dones)); break; end
    % update the candidate 
    dirList = vertcat(subdirlists{:});

end

%% Unzip dicm.gz (if needed) and make a new (/more decent) directory structure
% make the outDir list
outdirlist = cellfun(@(x) strrep(x, searchDir, outDir), subdirlists, 'uni', false);

% unzip and re-organize DICOM files
cellfun(@(x,y) unzip_redir(x, y, '*.dicom.zip'), subdirlists, outdirlist);

end % function fm_fw2dcm

function [subdirs, done] = searchtrg(theDir, trgwd)
% Search for the target folder
% 
% Inputs:
%    theDir       <str> the directory for searching for the target folder.
%    trgwd        <str> target directory. 
%
% Outputs:
%    subdirs      <cell> list of all sub-directories in theDir if the 
%                  target folder is not found. If the target folder is 
%                  found or there is no sub-directories in theDir, `theDir`
%                  will be saved as `subdirs`. 
%    done         <int/boo> whether the searching for `theDir` is finished.
%                  1 if the target folder is found or there is no 
%                  sub-directories in theDir; otherwise, 0 (continue
%                  searching).

done = 0;

% find all sub-directories
thisdir = dir(theDir);
thisdir(ismember({thisdir.name}, {'.', '..'})) = [];
thisdir(~[thisdir.isdir]) = [];

if isempty(thisdir)
    % if no sub-directories (done)
    subdirs = theDir;
    done = 1;
elseif any(ismember({thisdir.name}, trgwd))
    % the target folders/dirs are found (done)
    subdirs = theDir;
    done = 1;
else
    % continue searching
    subdirs = cellfun(@fullfile, {thisdir.folder}, {thisdir.name}, 'uni', false);
    subdirs = subdirs(:);
end

end % function searchtrg

function unzip_redir(thisDir, outDir, zipwd)
% Unzip DICOM zip files and re-organize DICOM files.
%
% Inputs:
%    thisDir      <str> directory where the DICOM files should be
%                  re-organized.
%    outDir       <str> directory to store the organized DICOM files.
%    zipwd        <str> wildcard for the zip DICOM files.

% make new dir if needed
if ~exist(outDir, 'dir'); mkdir(outDir); end

% identify single DICOM file
dcmdir = dir(fullfile(thisDir, '*.dcm'));
% copy the single DICOM file if it exists
if ~isempty(dcmdir)
    copyfile(fullfile(dcmdir.folder, dcmdir.name), ...
        fullfile(outDir, dcmdir.name));
end

% identify zip DICOM file
dcmzipdir = dir(fullfile(thisDir, zipwd));
% unzip and re-organize the zip DICOM file
if ~isempty(dcmzipdir)
    % unzip and remove the redundant folder
    unziplist = unzip(fullfile(dcmzipdir.folder, dcmzipdir.name), outDir);
    zipfolder = [strrep(dcmzipdir.name, '.zip', ''), filesep];
    unzipnew = cellfun(@(x) strrep(x, zipfolder, ''), unziplist, 'uni', false);
    cellfun(@movefile, unziplist, unzipnew);
    rmdir(fullfile(fileparts(unzipnew{1}), zipfolder));
end

end % function unzip_redir