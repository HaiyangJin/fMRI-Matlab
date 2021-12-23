function fs_samsrf_coreg(subjCode, t1File, struDir)
% This function re-coregister if the registration is bad. (Based on Sam's
% suggestion: run tkregister2 --mov NAME_OF_T1.nii --s SUBJECT --regheader 
% --noedit --reg register.dat (in the mir/) and Create the 
% Coregistration.txt in surf/.
%
% Inputs:
%     subjCode          <str> subject code in $SUBJECTS_DIR
%     t1File            <str> whole path to t1.nii file (with filename)
%     struDir           <str> $SUBJECTS_DIR
%
% Output:
%
% 
% Created by Haiyang Jin (15-Feb-2020)

if nargin < 3 || isempty(struDir)
    struDir = getenv('$SUBJECTS_DIR');
end

% mri path
mriPath = fullfile(struDir, subjCode, 'mri');

if nargin < 2 || isempty(t1File)
    t1File = fullfile(mriPath, sprintf('T1_%.nii', subjCode));
end

% register.dat file
regFile = fullfile(mriPath, 'register.dat');

% commands to get the output of registration
fscmd = sprintf('tkregister2 --mov %s --s %s --regheader --noedit --reg %s', ...
    t1File, subjCode, regFile);
[~, cmdOutput] = system(fscmd);

% split the output to cell of strings
cellOutput = splitlines(cmdOutput);

% select the Tmov and RegMat matrix
TmovCell = cellOutput(18:21, :);
RegMatCell = cellOutput(38:41, :);

% convert the cell of strings to a 4*4 cell
Tmov = reformat(TmovCell);
RegMat = reformat(RegMatCell);

% filename of the coregistration file
coregFile = fullfile(mriPath, '..', 'surf', 'Coregistration.txt');

% create the coregistration file
fm_mkfile(coregFile, vertcat(Tmov, RegMat));

end


function outcell = splitthecell(instring)
% This function split the string and remove the empty cell

% split the cell
cellsplit = split(instring);

% detect the empty string in the cell
isNotEmpty = ~cellfun(@isempty, cellsplit);

% remvoe the empty cell
outcell = cellsplit(isNotEmpty)';

end


function outcell = reformat(incell)
% This function reformats the cell of cells into a 4*4 cell

% remove ';'
temp = cellfun(@splitthecell, strrep(incell, ';', ''), 'uni', false);

% reformat into a 4*4 cell
outcell = vertcat(temp{:});

end