function fv_checklevel1(overlayFile)
% This function displays the results for contrast. 
% 
% Input:
%     overlayFile          the overlay file to be displayed (have to be the
%                          file in the contrast/ folder)
%
% Output:
%     display the overlay file on the inflated barin.
%
% Created by Haiyang Jin (29-Jan-2020)

if nargin < 1 || isempty(overlayFile)
    % set the default folder is FUNCTIONALS_DIR if it is not empty
    funcPath = getenv('FUNCTIONALS_DIR');
    if isempty(funcPath)
        startPath = pwd;
    else
        startPath = funcPath;
    end
    
    [theFn, thePath] = uigetfile({fullfile(startPath, '*.*')}', ...
        'Please select the overlay file(s) you want to display',...
        'MultiSelect', 'off');

    overlayFile = fullfile(thePath, theFn);
    
end

% slplit the filename for the overlay file
strings = strsplit(overlayFile, filesep);

hemi = fs_hemi(strings(end-2));
contrast = strings{end-1};
theLabel = sprintf('%s.%s', hemi, contrast);
funcPath = fullfile(filesep, strings{1:end-5});
subjCode = fs_subjcode(strings{end-4}, funcPath);
outputPath = '';
threshold = '';

% display the information of the overlay file
fprintf('\nDisplaying %s.\n', overlayFile);
fprintf('SubjCode: %s.\n', subjCode);
fprintf('Hemisphere: %s.\n', hemi);
fprintf('Contrast: %s.\n', contrast);

% display the overlay file
fv_label(subjCode, theLabel, outputPath, overlayFile, threshold, 0, '', 0);

end