function fs_screenshot_label(subjCode, fn_label, path_output, file_overlay)
% This function takes the screenshot of the label based with specific 
% contrast if there is. 
% 
% Created by Haiyang Jin (28/11/2019)

if nargin < 3 || isempty(path_output)
    path_output = '.';
end

if ~exist(path_output, 'dir')
    mkdir(path_output);
end

isContrast = 1;
if nargin < 4 || isempty(file_overlay)
    isContrast = 0;
end

FS = fs_setup;
hemi = fs_hemi(fn_label);

subjPath = fullfile(FS.subjects, subjCode);

% files to be used in the command
file_inf = fullfile(subjPath, 'surf', [hemi '.inflated']); % inflated file
file_annot = fullfile(subjPath, 'label', [hemi '.aparc.annot']); % annotation file
file_label = fullfile(subjPath, 'label', fn_label); % label file

fscmd1 = sprintf(['freeview -f %s:'... % the ?h.inflated file
    'annot=%s:annot_outline=yes:'... % the filename and settings for annotation file
    'label=%s:label_outline=yes:label_color=#FFFFFF'],...% the label file and settings
    file_inf, file_annot, file_label);

if isContrast
    fscmd2 = sprintf([':overlay=%s:overlay_threshold=2,4 '...
         '-colorscale'],...
         file_overlay);
else
    fscmd2 = '';
end

isLeft = strcmp(hemi, 'lh');
angle = 240 + 60 * isLeft;
fn_output = sprintf('%s-%s.png', fn_label, subjCode);
file_output = fullfile(path_output, fn_output); 
fscmd3 = sprintf(' -cam dolly 1.5 elevation %d -ss %s', angle, file_output); %

fscmd = [fscmd1 fscmd2 fscmd3];

system(fscmd);

fprintf('\nSave the screenshot of %s for %s successfully at %s\n\n', ...
    fn_label, subjCode, file_output);

end