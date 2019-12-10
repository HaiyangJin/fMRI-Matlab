function isok = fs_screenshot_label(subjCode, fn_label, output_path, file_overlay, color_label)
% This function takes the screenshot of the label based with specific 
% contrast if there is. 
%
% file_overlay: the functional file (beta, or sig file)
% 
% Created by Haiyang Jin (28/11/2019)
% Updated by Haiyang Jin (1/12/2019) Plot multiple labels (same hemisphere)
% Updated by Haiyang Jin (10/12/2019) could plot overlay only witout labels

isok = 1;

%% Obtain information from input arguments
% determine if there is label information to be shown
% if there is label information, 
if ischar(fn_label) && length(fn_label) < 3 % if only contains info of hemi
    hemi = fn_label;
    fn_label = '';
elseif ischar(fn_label) % if only one label but it is char
    fn_label = {fn_label};
    hemi = fs_hemi(fn_label);
else % 
    % make sure all labels are for the same hemisphere
    [hemi, nHemi] = fs_hemi_multi(fn_label);
    if nHemi ~= 1
        error('Please make sure all labels used are for the same hemisphere.');
    end
end
nLabel = numel(fn_label); % number of labels for visualization


if nargin < 3 || isempty(output_path)
    output_path = fullfile('.');
end
output_path = fullfile(output_path, 'Label_Screenshots');
if ~exist(output_path, 'dir'); mkdir(output_path); end % create the folder if necessary

% create the freesurfer commands for the functional data
if nargin < 4 || isempty(file_overlay)
    fscmd_overlay = '';
else
    fscmd_overlay = sprintf([':overlay=%s:overlay_threshold=2,4 '...
        '-colorscale'],...
        file_overlay);
end

% colors used for labels
if nargin < 5 || isempty(color_label)
    color_label = {'#FFFFFF', '#33cc33', '#0000FF', '#FFFF00'}; % white, green, blue, yellow
end

%% Create commands for each "section"
% FreeSurfer setup 
FS = fs_setup;

% surface files and the annotation file
subjPath = fullfile(FS.subjects, subjCode);
file_inf = fullfile(subjPath, 'surf', [hemi '.inflated']); % inflated file
file_annot = fullfile(subjPath, 'label', [hemi '.aparc.annot']); % annotation file

fscmd_surf = sprintf(['freeview -f %s:'... % the ?h.inflated file
    'annot=%s:annot_outline=yes:'... % the filename and settings for annotation file
    ],...% the label file and settings
    file_inf, file_annot);

% the label files
fscmd_label = '';
for iLabel = 1:nLabel
    
    theLabel = fn_label{iLabel};
    file_thelabel = fullfile(subjPath, 'label', theLabel); % label file
    color_thelabel = color_label{iLabel};
    
    % make sure there is the label for this subject
    isAvailable = fw_checklabel(theLabel, subjCode);
    if ~isAvailable
        isok = 0;
        warning('Cannot find label %s for subject %s.\n', theLabel, subjCode);
        return; % quit this function now
    end
    
    fscmd_thislabel = sprintf('label=%s:label_outline=yes:label_color=%s:',...
        file_thelabel, color_thelabel);
    
    fscmd_label = [fscmd_label fscmd_thislabel]; %#ok<AGROW>
end

% the camera angle
isLeft = strcmp(hemi, 'lh');
if contains(fn_label, 'o-vs-scr')
    angle = 180 * ~isLeft;
    fscmd_angle = sprintf('azimuth %d', angle); % camera angle for LOC
else
    angle = 240 + 60 * isLeft;
    fscmd_angle = sprintf('elevation %d', angle);
end
fscmd_camera = [' -cam dolly 1.5 ' fscmd_angle];


% the filename of the screenshot
if isempty(fn_label)
    name_labels = '';
else
    name_labels = sprintf(repmat('%s:', 1, nLabel), fn_label{:});
    name_labels = erase(name_labels, {'roi.', '.label'}); % shorten filenames
end

fn_output = sprintf('%s%s.png', name_labels, subjCode);
file_output = fullfile(output_path, fn_output);
fscmd_output = sprintf(' -ss %s', file_output); %

%% combine the commands and run 
% combine the command together
fscmd = [fscmd_surf fscmd_label fscmd_overlay fscmd_camera fscmd_output];

% run the freesurfer command
system(fscmd);
fprintf('\nSave the screenshot of %s for %s successfully at %s\n\n', ...
    name_labels, subjCode, file_output);

end