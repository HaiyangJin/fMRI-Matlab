function isok = fs_fvlabel(subjCode, labelFn, outputPath, ...
    overlayFile, threshold, isfsavg, colorLabel, saveSS)
% This function takes the screenshot of the label based with specific 
% contrast if there is. 
%
% Inputs:
%    subjCode           subject code in $SUBJECTS_DIR
%    labelFn           a list (cell) of label names
%    outputPath        where the screenshots will be saved
%    overlayFile       the overlay file to be displayed
%    colorLabel        colors used for each label in order
% Output:
%    isok               if all labels in "labelFn" are available for this subjCode
%    screenshots of labels saved in outputPath
% 
% Created by Haiyang Jin (28-Noc-2019)
% Updated by Haiyang Jin (1-Dec-2019) Plot multiple labels (same hemisphere)
% Updated by Haiyang Jin (10-Dec-2019) could plot overlay only witout labels

isok = 1;

%% Obtain information from input arguments
% determine if there is label information to be shown
% if there is label information, 
if ischar(labelFn) && length(labelFn) < 3 % if only contains info of hemi
    hemi = labelFn;
    labelFn = '';
elseif ischar(labelFn) % if only one label but it is char
    labelFn = {labelFn};
    hemi = fs_hemi(labelFn);
else % 
    % make sure all labels are for the same hemisphere
    [hemi, nHemi] = fs_hemi_multi(labelFn);
    if nHemi ~= 1
        error('Please make sure all labels used are for the same hemisphere.');
    end
end
nLabel = numel(labelFn); % number of labels for visualization


if nargin < 5 || isempty(threshold)
    threshold = '2,4';
end

if nargin < 3 || isempty(outputPath)
    outputPath = fullfile('.');
end

% create the freesurfer commands for the functional data
if nargin < 4 || isempty(overlayFile)
    fscmd_overlay = '';
else
    fscmd_overlay = sprintf(['overlay=%s:overlay_threshold=%s '...
        '-colorscale'],...
        overlayFile, threshold);
end

% detect which overlay is shown 
if ~isempty(labelFn)
    contrasts = fs_label2contrast(labelFn);
    whichOverlay = find(cellfun(@(x) contains(overlayFile, x), {contrasts}), 1);
    if isempty(whichOverlay)
        whichOverlay = 0;
        contrast = contrasts{1};
    else
        contrast = contrasts{whichOverlay};
    end
else
    contrast = '';
    whichOverlay = 0;
end

% if show ?h.inflated of fsaverage (probably this should be determined by
% the overlay file???)
if nargin < 6 || isempty(isfsavg)
    isfsavg = 0;
end
if isfsavg; avgStr = '_fsavg'; else; avgStr = '_self'; end

% colors used for labels
if nargin < 7 || isempty(colorLabel)
    colorLabel = {'#FFFFFF', '#33cc33', '#0000FF', '#FFFF00'}; % white, green, blue, yellow
end

if nargin < 8 || isempty(saveSS)
    saveSS = 0;
end

outputFolder = sprintf('Label_Screenshots%s_%s', avgStr, strrep(threshold, ',', '-'));
outputPath = fullfile(outputPath, outputFolder);
if ~exist(outputPath, 'dir'); mkdir(outputPath); end % create the folder if necessary


%% Create commands for each "section"
% FreeSurfer setup 
structPath = getenv('SUBJECTS_DIR');

% surface files and the annotation file
if isfsavg
    subjCodeTemp = 'fsaverage';
else
    subjCodeTemp = subjCode;
end
subjPath = fullfile(structPath, subjCodeTemp);
inflateFile = fullfile(subjPath, 'surf', [hemi '.inflated']); % inflated file
annotFile = fullfile(subjPath, 'label', [hemi '.aparc.annot']); % annotation file

fscmd_surf = sprintf(['freeview -f %s:'... % the ?h.inflated file
    'annot=%s:annot_outline=yes:'... % the filename and settings for annotation file
    ],...% the label file and settings
    inflateFile, annotFile);

% the label files
fscmd_label = '';
for iLabel = 1:nLabel
    
    theLabelFn = labelFn{iLabel};
    thelabelFile = fullfile(structPath, subjCode, 'label', theLabelFn); % label file
    thelabelColor = colorLabel{iLabel};
    
    % make sure there is the label for this subject
    isAvailable = fs_checklabel(theLabelFn, subjCode);
    if ~isAvailable
        isok = 0;
        warning('Cannot find label %s for subject %s.\n', theLabelFn, subjCode);
        continue; % quit this function now
    end
    
    fscmd_thislabel = sprintf('label=%s:label_outline=yes:label_color=%s:',...
        thelabelFile, thelabelColor);
    
    fscmd_label = [fscmd_label fscmd_thislabel]; %#ok<AGROW>
end

% the camera angle
fscmd_camera = fs_camangle(contrast, hemi);

% the filename of the screenshot
if isempty(labelFn)
    nameLabels = '';
else
    nameLabels = sprintf(repmat('%s:', 1, nLabel), labelFn{:});
    nameLabels = erase(nameLabels, {'roi.', '.label'}); % shorten filenames
end

if saveSS
    outputFn = sprintf('%s%s%s_%d.png', nameLabels, subjCode, avgStr, whichOverlay);
    outputFile = fullfile(outputPath, outputFn);
    fscmd_output = sprintf(' -ss %s', outputFile); %
else
    fscmd_output = '';
end

%% combine the commands and run 
% combine the command together
fscmd = [fscmd_surf fscmd_label fscmd_overlay fscmd_camera fscmd_output];

% run the freesurfer command
system(fscmd);
if saveSS
    fprintf('\nSave the screenshot of %s for %s successfully at %s\n\n', ...
        nameLabels, subjCode, outputFile);
end

end