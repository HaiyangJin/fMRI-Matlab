function isok = fs_screenshot_label(subjCode, label_fn, output_path, ...
    overlay_file, threshold, isfsavg, color_label, saveScreenshots)
% This function takes the screenshot of the label based with specific 
% contrast if there is. 
%
% Inputs:
%    subjCode           subject code in $SUBJECTS_DIR
%    label_fn           a list (cell) of label names
%    output_path        where the screenshots will be saved
%    overlay_file       the overlay file to be displayed
%    color_label        colors used for each label in order
% Output:
%    isok               if all labels in "label_fn" are available for this subjCode
%    screenshots of labels saved in output_path
% 
% Created by Haiyang Jin (28/11/2019)
% Updated by Haiyang Jin (1/12/2019) Plot multiple labels (same hemisphere)
% Updated by Haiyang Jin (10/12/2019) could plot overlay only witout labels

isok = 1;

%% Obtain information from input arguments
% determine if there is label information to be shown
% if there is label information, 
if ischar(label_fn) && length(label_fn) < 3 % if only contains info of hemi
    hemi = label_fn;
    label_fn = '';
elseif ischar(label_fn) % if only one label but it is char
    label_fn = {label_fn};
    hemi = fs_hemi(label_fn);
else % 
    % make sure all labels are for the same hemisphere
    [hemi, nHemi] = fs_hemi_multi(label_fn);
    if nHemi ~= 1
        error('Please make sure all labels used are for the same hemisphere.');
    end
end
nLabel = numel(label_fn); % number of labels for visualization


if nargin < 5 || isempty(threshold)
    threshold = '2,4';
end

if nargin < 3 || isempty(output_path)
    output_path = fullfile('.');
end
output_path = fullfile(output_path, ['Label_Screenshots_' strrep(threshold, ',', '-')]);
if ~exist(output_path, 'dir'); mkdir(output_path); end % create the folder if necessary

% create the freesurfer commands for the functional data
if nargin < 4 || isempty(overlay_file)
    fscmd_overlay = '';
else
    fscmd_overlay = sprintf(['overlay=%s:overlay_threshold=%s '...
        '-colorscale'],...
        overlay_file, threshold);
end

% detect which overlay is shown 
if ~isempty(label_fn)
    contrasts = fs_label2contrast(label_fn);
    whichOverlay = find(cellfun(@(x) contains(overlay_file, x), {contrasts}), 1);
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

% if show ?h.inflated of fsaverage
if nargin < 6 || isempty(isfsavg)
    isfsavg = 0;
end

% colors used for labels
if nargin < 7 || isempty(color_label)
    color_label = {'#FFFFFF', '#33cc33', '#0000FF', '#FFFF00'}; % white, green, blue, yellow
end

if nargin < 8 || isempty(saveScreenshots)
    saveScreenshots = 1;
end

%% Create commands for each "section"
% FreeSurfer setup 
FS = fs_setup;

% surface files and the annotation file
if isfsavg
    subjCode_surf = 'fsaverage';
else
    subjCode_surf = subjCode;
end
subjPath_Surf = fullfile(FS.subjects, subjCode_surf);
file_inf = fullfile(subjPath_Surf, 'surf', [hemi '.inflated']); % inflated file
file_annot = fullfile(subjPath_Surf, 'label', [hemi '.aparc.annot']); % annotation file

fscmd_surf = sprintf(['freeview -f %s:'... % the ?h.inflated file
    'annot=%s:annot_outline=yes:'... % the filename and settings for annotation file
    ],...% the label file and settings
    file_inf, file_annot);

% the label files
fscmd_label = '';
for iLabel = 1:nLabel
    
    theLabel = label_fn{iLabel};
    file_thelabel = fullfile(FS.subjects, subjCode, 'label', theLabel); % label file
    color_thelabel = color_label{iLabel};
    
    % make sure there is the label for this subject
    isAvailable = fs_checklabel(theLabel, subjCode);
    if ~isAvailable
        isok = 0;
        warning('Cannot find label %s for subject %s.\n', theLabel, subjCode);
        continue; % quit this function now
    end
    
    fscmd_thislabel = sprintf('label=%s:label_outline=yes:label_color=%s:',...
        file_thelabel, color_thelabel);
    
    fscmd_label = [fscmd_label fscmd_thislabel]; %#ok<AGROW>
end

% the camera angle
fscmd_camera = fs_camangle(contrast, hemi);

% the filename of the screenshot
if isempty(label_fn)
    name_labels = '';
else
    name_labels = sprintf(repmat('%s:', 1, nLabel), label_fn{:});
    name_labels = erase(name_labels, {'roi.', '.label'}); % shorten filenames
end

if saveScreenshots
    if isfsavg; avg = '_avg'; else; avg = ''; end
    fn_output = sprintf('%s%s%s_%d.png', name_labels, subjCode, avg, whichOverlay);
    file_output = fullfile(output_path, fn_output);
    fscmd_output = sprintf(' -ss %s', file_output); %
else
    fscmd_output = '';
end

%% combine the commands and run 
% combine the command together
fscmd = [fscmd_surf fscmd_label fscmd_overlay fscmd_camera fscmd_output];

% run the freesurfer command
system(fscmd);
if saveScreenshots
    fprintf('\nSave the screenshot of %s for %s successfully at %s\n\n', ...
        name_labels, subjCode, file_output);
end

end