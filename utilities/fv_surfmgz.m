function mgzFile = fv_surfmgz(mgzFile, surfType, threshold)
% function fv_surfmgz(mgzFile, surfType, threshold)
%
% This function displays *.mgz file (for surface) in FreeView. [For
% displaying *.mgz for volume, please use fv_volmgz.m instead.]
%
% Inputs: 
%     mgzFile            <string> or <a cell of strings> *.mgz file (with 
%                        path) [fv_mgz.m could be used to open a gui for 
%                        selecting files.]
%     surfType           <string> the base surface file to be displayed
%                        ('inflated', 'white', 'pial', 'sphere')
%     threshold          <string> the threshold used for mgzFile
%                        [low,(mid,)high(,percentile)]
%
% Output:
%     Open FreeView to display the mgz (mgh) file
%
% Created by Haiyang Jin (21-Jan-2020)

dispMgz = 1;

if nargin < 1 || isempty(mgzFile)
    dispMgz = 0; % do not display the mgz File (only display the surface)
elseif ischar(mgzFile)
    % convert mgzFile to a cell if it is string
    mgzFile = {mgzFile}; 
end

if nargin < 2 || isempty(surfType)
    surfType = {'inflated'};
elseif ischar(surfType)
    surfType = {surfType};
end

if nargin < 3 || isempty(threshold)
    threshold = ''; % 0.5,1
end

if dispMgz
    % get the path from mgzFile
    pathCell = cellfun(@fileparts, mgzFile, 'uni', false);
    thePath = unique(pathCell);  % the path to these files
    assert(numel(thePath) == 1); % make sure all the files are in the same folder
    thePath = thePath{1}; % convert cell to string
    
    % decide the hemi for each file
    hemis = fs_hemi_multi(mgzFile, 0);  % which hemi it is (they are)?
    hemiNames = unique(hemis);
    
    % make sure the selected *.mgz is surface files
    notSurf = cellfun(@isempty, hemis);
    if any(notSurf)
        error('Please make sure the file %s is a surface file.\n', mgzFile{notSurf});
    end
    
else
    % only display the surface but not the mgz files
    hemiNames = {'lh', 'rh'};
    tempPath = getenv('SUBJECTS_DIR');
    if isempty(tempPath)
        tempPath = pwd;
    end
    theSubjPath = uigetdir(tempPath, 'Please select the subject folder for checking...');
    thePath = fullfile(theSubjPath, 'surf');
end

nHemi = numel(hemiNames);
fscmd_hemis = cell(nHemi, 1);
% create the cmd for the two hemispheres separately
for iHemi = 1:nHemi
    
    thisHemi = hemiNames{iHemi};
    
    % cmd for overlay file (*.mgz)
    if dispMgz
        % make sure only one type of surface is slected when disply mgz
        % files
        assert(numel(surfType) == 1, 'Please define only one type of surface.');
        isThisHemi = strcmp(thisHemi, hemis);
        theseMgzFile = mgzFile(isThisHemi);
        fscmd_mgz = sprintf(repmat('overlay=%s:', 1, numel(theseMgzFile)), theseMgzFile{:});
        fscmd_threshold = sprintf('overlay_threshold=%s', threshold);
    else
        fscmd_mgz = '';
        fscmd_threshold = '';
    end
    
    % file for the surface file
    surfFilename = cellfun(@(x) sprintf('%s.%s', thisHemi, x), surfType, 'uni', false);
    surfFile = fullfile(thePath, '..', 'surf', surfFilename);
    isAvail = cellfun(@(x) exist(x, 'file'), surfFile);
    % assert the surface file is available
    if ~all(isAvail)
        error('Cannot find surface file %s.', surfFilename{~isAvail});
    end
    
    % file for the anaotation file
    annotFile = fullfile(thePath, '..', 'label', [thisHemi '.aparc.annot']); % annotation file
    assert(logical(exist(annotFile, 'file')));  % make sure the file is avaiable
    
    % cmd for surface file with annotation 
    [tempSurf, tempAnnot] = ndgrid(surfFile, {annotFile});
    tempCmdSurf = horzcat(tempSurf, tempAnnot)';
    fscmd_surf = sprintf([' -f %s:'... % the ?h.inflated file
        'annot=%s:annot_outline=yes:'... % the filename and settings for annotation file
        ],...% the label file and settings
        tempCmdSurf{:});
    
    % cmd for this hemisphere
    fscmd_hemis{iHemi} = [fscmd_surf fscmd_mgz fscmd_threshold];
    
end

% combine the commands for two 
fscmd_hemi = [fscmd_hemis{:}];

% other cmd
fscmd_other = ' -colorscale -layout 1 -viewport 3d';

% put all commands together
fscmd = ['freeview' fscmd_hemi fscmd_other];
system(fscmd);

end