function [sdataFile, fscmd] = fv_surf(sdataFile, subjCode, varargin)
%
% This function displays *.mgz file (for surface) in FreeView. [For
% displaying *.mgz for volume, please use fv_vol.m instead.] Note: the
% *.mgz file has to be in $SUBJECTS_DIR folder. 
%
% Inputs: 
%    surfFile         <str> or <cell str> *.mgz file (with path) 
%                      [fv_uigetfile.m could be used to open a gui for 
%                      selecting files.]
%    subjCode         <str> the subject code in %SUBJECTS_DIR.
%
% Varargin:
%    .surftype        <cell str> the surface type to be displayed
%                      Default is 'infalted'; 
%    .threshold       <str> threshold to be displayed in Freeview.
%                      Default is ''. 
%    'annot           <str> name of the annotation files. Default is '', 
%                      which will display 'aparc'. Others:'a2009s',
%                      'a2005s';
%    .overlay         <str> the REAL functional surface data. When
%                      'overlay' is not empty, 'overlay' will be used as 
%                      the overlay.
%    .runcmd          <boo> 1: run the fscmd to open freeview. 0: do
%                      not run freeview and only output fscmd.
%
% Output:
%    surfFile         <string> the filename of mgzFile displayed in
%                      freeview.
%    fscmd            <string> the FreeSurfer command used here.
%
% Example: display the inflated surface overlaied with *.mgz file in any
% folder. 
% fv_surf; % and then select the fsaverage/ folder. % next: add the
% *.mgz file to 'overlay'.
%
% Created by Haiyang Jin (21-Jan-2020)
%
% See also:
% fv_uigetfile, fv_vol

dispMgz = 1;

% default options
defaultOpt=struct(...
    'surftype', 'inflated', ... % surface type
    'threshold', '', ... % default threshold
    'annot', 'aparc',... % display aparc
    'overlay', '', ... 
    'runcmd', 1 ... 
    );

opts = fm_mergestruct(defaultOpt, varargin{:});

surfType = opts.surftype;
annot = opts.annot;

if ischar(surfType); surfType = {surfType}; end
if ~isempty(annot) && ~startsWith(annot, '.')
    annot = ['.' annot];
end

if ~exist('sdataFile', 'var') || isempty(sdataFile)
    dispMgz = 0; % do not display the surface file (only display the surface)
elseif ischar(sdataFile)
    % convert mgzFile to a cell if it is string
    sdataFile = {sdataFile}; 
end

if dispMgz
    % decide the hemi for each file
    hemis = fm_hemi_multi(sdataFile, 0, 0);  % which hemi it is (they are)?
    hemiNames = unique(hemis);

    % make sure the selected *.mgz is surface files (i.e., contains
    % hemisphere information)
    notSurf = cellfun(@isempty, hemis);
    if any(notSurf)
        error('Please make sure the file %s is a surface file.\n', sdataFile{notSurf});
    end

    if ~exist('subjCode', 'var') || isempty(subjCode)
        surfData = fs_readfunc(sdataFile{1});
        if numel(surfData) == 163842
            subjCode = 'fsaverage';
        else
            error('Please define "subjCode".')
        end
    end
    thePath = fullfile(getenv('SUBJECTS_DIR'), subjCode, 'surf');

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
        if ~isempty(opts.overlay)
            sdataFile = {opts.overlay};
        end
        
        assert(numel(surfType) == 1, 'Please define only one type of surface.');
        isThisHemi = strcmp(thisHemi, hemis);
        theseMgzFile = sdataFile(isThisHemi);
        fscmd_mgz = sprintf(repmat('overlay=%s:', 1, numel(theseMgzFile)), theseMgzFile{:});
        fscmd_threshold = sprintf('overlay_threshold=%s', opts.threshold);
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
    annotFn = sprintf('%s%s.annot', thisHemi, annot);
    annotFile = fullfile(thePath, '..', 'label', annotFn); % annotation file
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
if opts.runcmd; system(fscmd); end

end