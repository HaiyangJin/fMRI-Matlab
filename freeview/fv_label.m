function isok = fv_label(subjCode, labelList, outPath, overlayFile, ...
    threshold, colorLabel, saveSS)
% isok = fv_label(subjCode, labelFn, outputPath, overlayFile, ...
%    threshold, colorLabel, saveSS)
%    
% This function takes the screenshot of the label based with specific 
% contrast if there is. 
%
% Inputs:
%    subjCode           <string> subject code in $SUBJECTS_DIR.
%    labelFn            <cell of strings> a list (cell) of label names.
%    outputPath         <string> where the screenshots will be saved.
%    overlayFile        <string> the overlay file to be displayed.
%    threshold          <string> p-value threshold.
%    colorLabel         <string> colors used for each label in order.
%    saveSS             <logical> 1: save screenshots; 0: do not save.
%
% Output:
%    isok               <logical> if all labels in "labelFn" are available 
%                        for this subjCode
%    screenshots of labels saved in outputPath
% 
% % Example 1:
% fv_label('fsaverage', 'lh');
%
% % Example 2:
% fv_label('fsaverage', 'lh.cortex.label');
%
% Created by Haiyang Jin (28-Noc-2019)
% 
% See also:
% fv_check1st; fs_screenshot_label

isok = 1;

%% Obtain information from input arguments
% determine if there is label information to be shown
% if there is label information, 
if ischar(labelList) && length(labelList) < 3 % if only contains info of hemi
    hemi = labelList;
    labelList = '';
    iscon = 1;
elseif ischar(labelList) % if only one label but it is char
    labelList = {labelList};
    hemi = fm_2hemi(labelList);
    iscon = contains(labelList, '-vs-');
else % 
    % make sure all labels are for the same hemisphere
    [hemi, nHemi] = fm_hemi_multi(labelList);
    if nHemi ~= 1
        error('Please make sure all labels used are for the same hemisphere.');
    end
end
nLabel = numel(labelList); % number of labels for visualization


if ~exist('threshold', 'var') || isempty(threshold)
    threshold = '2,4';
end

if ~exist('outPath', 'var') || isempty(outPath)
    outPath = pwd;
end

% create the freesurfer commands for the functional data
if ~exist('overlayFile', 'var') || isempty(overlayFile)
    overlayFile = '';
    fscmd_overlay = '';
else
    fscmd_overlay = sprintf(['overlay=%s:overlay_threshold=%s '...
        '-colorscale'],...
        overlayFile, threshold);
end

% detect which overlay is shown 
if isempty(labelList) || ~iscon
    contrast = '';
    whichOverlay = 0;
else
    contrasts = fm_2contrast(labelList);
    whichOverlay = find(cellfun(@(x) contains(overlayFile, x), {contrasts}), 1);
    if isempty(whichOverlay)
        whichOverlay = 0;
        contrast = contrasts{1};
    else
        contrast = contrasts{whichOverlay};
    end
end

% colors used for labels
if ~exist('colorLabel', 'var') || isempty(colorLabel)
    colorLabel = {'#FFFFFF', '#33cc33', '#0000FF', '#FFFF00'}; % white, green, blue, yellow
end

if ~exist('saveSS', 'var') || isempty(saveSS)
    saveSS = 0;
end

% if show ?h.inflated of fsaverage (probably this should be determined by
% the overlay file???)
if ~isempty(overlayFile) && contains('fsaverage', overlayFile)
    template = 'fsaverage';
else
    template = 'self';
end
outputFolder = sprintf('Label_Screenshots%s_%s', template, strrep(threshold, ',', '-'));
outPath = fullfile(outPath, outputFolder);
if ~exist(outPath, 'dir'); mkdir(outPath); end % create the folder if necessary


%% Create commands for each "section"
% FreeSurfer setup 
structPath = getenv('SUBJECTS_DIR');

% surface files and the annotation file
trgSubj = fs_trgsubj(subjCode, template);
templatePath = fullfile(structPath, trgSubj);
inflateFile = fullfile(templatePath, 'surf', [hemi '.inflated']); % inflated file
annotFile = fullfile(templatePath, 'label', [hemi '.aparc.annot']); % annotation file

fscmd_surf = sprintf(['freeview -f %s:'... % the ?h.inflated file
    'annot=%s:annot_outline=yes:'... % the filename and settings for annotation file
    ' &'],...% the label file and settings
    inflateFile, annotFile);

% the label files
fscmd_label = '';
for iLabel = 1:nLabel
    
    theLabelFn = labelList{iLabel};
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
if isempty(labelList)
    nameLabels = '';
else
    nameLabels = sprintf(repmat('%s:', 1, nLabel), labelList{:});
    nameLabels = erase(nameLabels, {'roi.', '.label'}); % shorten filenames
end

if saveSS
    outputFn = sprintf('%s%s%s_%d.png', nameLabels, subjCode, template, whichOverlay);
    outputFile = fullfile(outPath, outputFn);
    fscmd_output = sprintf(' -ss %s', outputFile); %
else
    fscmd_output = '';
end

%% combine the commands and run 
% combine the command together
fscmd = [fscmd_surf fscmd_label fscmd_overlay fscmd_camera fscmd_output '&'];

% run the freesurfer command
system(fscmd);
if saveSS
    fprintf('\nSave the screenshot of %s for %s successfully at %s\n\n', ...
        nameLabels, subjCode, outputFile);
end

end