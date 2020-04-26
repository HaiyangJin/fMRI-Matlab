function varargout = fs_readlabel(labelFn, subjCode, struPath)
% [labelMat, nVtx] = fs_readlabel(labelFn, [subjCode='fsaverage', struPath])
%
% This function loads label file in FreeSurfer to matrix in Matlab. Note:
% all the vertex indices are added one when loading into Matlab. This is
% due to that the row number in Shell starts from 0 and the row number in
% Matlab starts from 1. 
% [read_label.m from FreeSurfer matlab]
%
% Inputs:
%    labelFn         <string> filename of the label file (with or without
%                     path). If path is included in labelFn, 'subjCode'
%                     and struPath will be ignored. Default is
%                     'lh.cortex.label'.
%    subjCode        <string> subject code in struPath. Default is
%                     fsaverage.
%    struPath        <string> $SUBJECTS_DIR.
%
% Outputs:
%    labelMat        <numeric array> the data matrix from the label file.
%    nVtx            <numeric> number of vertices.
%
% Example 1 (read a label in the current working directory):
% fs_readlabel('./lh.cortex.label');
%
% Created by Haiyang Jin (28-Nov-2019)

if ~exist('labelFn', 'var') || isempty(labelFn)
    labelFn = 'lh.cortex.label';
    warning('''%s'' is loaded by default.', labelFn);
end

% check if the path is available
filepath = fileparts(labelFn);

if isempty(filepath)
    if ~exist('subjCode', 'var') || isempty(subjCode)
        subjCode = 'fsaverage';
        warning('''fsaverage'' is used as ''subjCode'' by default.');
    end
    % use SUBJECTS_DIR as the default subject path
    if ~exist('struPath', 'var') || isempty(struPath)
        struPath = getenv('SUBJECTS_DIR');
    end
    labelFile = fullfile(struPath, subjCode, 'label', labelFn);
else
    % use the label filename directly
    labelFile = labelFn;
end

% make sure the label file is available
if ~exist(labelFile, 'file')
    if endsWith(labelFile, '.label')
        warning('Cannot find the label file: %s for %s.', labelFile, subjCode);
    end
    varargout = {[], [], [], []};
    return;
end

%% Load the label file
% use importdata to read label instead
% read the label file
dataMat = importdata(labelFile, ' ', 2);

% the data from the label file ([vertex number, x, y, z, activation])
labelMat = dataMat.data;

% vertex indices in FreeSurfer starts from 0 while vertex indices in Matlab
% starts from 1
labelMat(:, 1) = labelMat(:, 1) + 1;

% number of vertices
nVtx = str2double(dataMat.textdata{2, 1});

% save the output
varargout{1} = labelMat;
varargout{2} = nVtx;

%% From read_label.m [backup]
% % open it as an ascii file
% fid = fopen(labelFile, 'r') ;
% if(fid == -1)
%   fprintf('ERROR: could not open %s\n',labelFile);
%   return;
% end
% 
% fgets(fid) ;
% if(fid == -1)
%   fprintf('ERROR: could not open %s\n',labelFile);
%   return;
% end
% 
% line = fgets(fid) ;
% nv = sscanf(line, '%d') ;
% l = fscanf(fid, '%d %f %f %f %f\n') ;
% l = reshape(l, 5, nv) ;
% labelMat = l' ;
% 
% fclose(fid) ;

end