function fs_mkfsgd(gdTable, gdFilename, tag, display)
% fs_mkfsgd(gdTable, gdFilename, tag, display)
% 
% This function creates the FreeSurfer Group Descriptor (FSGD) for running
% group analysis in FreeSurfer. In this group analysis, you can control
% some variables (e.g., age or gender).
%
% Inputs:
%     gdTable           <table> The table contains all the information. 
%                        Each row is for one participant. The first column 
%                        is the subjCode. The second column is 'Class' 
%                        [the combinations of levels in discrete factors].
%                        The third and following columns are for 'Variables' 
%                        [the continous variables]. 
%     gdFilename        <string> full path where to save the fsgd file. If
%                        no path is defined, this file will be saved at
%                        $FUNCTIONALS_DIR if it is not empty. Otherwise,
%                        the file will be saved in the current directory.
%     tag               <string> or <cell of strings> n * 1 matrix. Each
%                        row is one tag. 
%     display           <cell of strings> icons used for each class in the
%                        display.
%    
% Output:
%     a FreeSurfer Group Descriptor file.
%
% Example:
%     SubjCode = {'subjid1'; 'subjid2'};
%     Class = {'Class1'; 'Class2'};
%     Age = [10; 20];
%     Weight = [100; 200];
%     IQ = [1000; 2000];
% 
%     gdTable = table(SubjCode, Class, Age, Weight, IQ);
% 
%     fs_mkfsgd(gdTable, '~/Desktop/gender_age') 
%
% Created by Haiyang Jin (31-March-2020)

%% obtain the default settings

if nargin < 2 || isempty(gdFilename)
    gdFilename = 'this.fsgd';
elseif ~endsWith(gdFilename, '.fsgd')
    gdFilename = [gdFilename, '.fsgd'];
end

[thispath, thisfn] = fileparts(gdFilename);
if isempty(thispath)
    if ~isempty(getenv('FUNCTIONALS_DIR'))
        thePath = getenv('FUNCTIONALS_DIR');
    else
        thePath = '.';
    end
    gdFilename = fullfile(thePath, gdFilename);
end

if nargin < 3 || isempty(tag)
    tag = '';
elseif isstring(tag)
    tag = {tag};
elseif size(tag, 1) == 1
    tag = tag';
end
nTag = numel(tag);

if nargin < 4 || isempty(display)
    display = {
        'plus blue';
        'circle green'};
elseif size(display, 1) == 1
    display = display';
end

%% Gather information for FreeSurfer Group Descriptor
% all the levels for Class
class = unique(gdTable.Class');
nClass = numel(class);

% all variables
variable = gdTable.Properties.VariableNames(3:end);

% number of rows and columns for fsgd
[nGdRow, nGdCol] = size(gdTable);
nRows = 1 + 1 + nClass + nTag + 1 + nGdRow;
nCol = max(nGdCol, 3);  % there will be 3 columns for Class

% empty cell for fsgd
fsgd = cell(nRows, nCol);

%% Save the contents to fsgd
% the first two rows
fsgd(1, 1:2) = {'GroupDescriptorFile', 1};
fsgd(2, 1) = {thisfn};

% rows for Class
fsgd(3 + (0:nClass-1), 1) = repmat({'Class'}, nClass, 1);
fsgd(3 + (0:nClass-1), 2) = class';
fsgd(3 + (0:nClass-1), 3) = display;

% tag
theRowTag = 1+1+nClass+1;
if ~isempty(tag)
    fsgd(theRowTag + (0:nTag-1), 1) = tag;
end

% variables
theRowVar = theRowTag + nTag;
fsgd(theRowVar, 1:nGdCol-2+1) = horzcat('Variables', variable);

% input
fsgd(theRowVar+ (1:nGdRow), 1:nGdCol+1) = horzcat(repmat({'Input'}, nGdRow, 1), table2cell(gdTable)); 

%% make the file for FSGD
fm_createfile(gdFilename, fsgd);

end