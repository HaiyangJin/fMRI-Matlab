function dirList = fp_mkbidsignore(dirList, bidsDir)
% dirList = fp_mkbidsignore(dirList, bidsDir)
%
% Make a bids ignore file (.bidsignore) in the fmriPrep project direcotry 
% to ignore some folders/files. 
%
% Inputs:
%    dirList       <cell str> list of folders/files to be ignored in the
%                   fmriPrep project directory.
%    bidsDir       <str> the BIDS directory. Default is fp_bidsdir.
%
% % Example:
% dirList = fp_mkbidsignore;
%
% Created by Haiyang Jin (2021-10-13)

if ~exist('dirList', 'var') || isempty(dirList)
    dirList = {'tmp_dcm2bids/'; 'temp/'; 'codes/'};
elseif size(dirList, 2) > 1
    % make it into a column
    dirList = dirList(:);
end

if ~exist('bidsDir', 'var') || isempty(bidsDir)
    bidsDir = fp_bidsdir;
end

% add an empty cell at the end
if ~isempty(dirList(end))
    dirList = vertcat(dirList, {''});
end

% make the bids ignore file
fm_mkfile(fullfile(bidsDir, '.bidsignore'), dirList);

end