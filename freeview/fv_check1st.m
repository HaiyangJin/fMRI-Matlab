function fv_check1st(overlayFile)
% fv_check1st(overlayFile)
%
% This function displays the results for contrast (reuslts of the
% first-lelvel analysis).
%
% Input:
%     overlayFile        <string> the overlay file to be displayed (have 
%                          to be in the contrast/ folder). [If empty,
%                          a GUI will open for selecting the overlay file.]
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
        ['Please select the overlay file(s) [for results of the first-'...
        'level analysis] you want to display'],...
        'MultiSelect', 'off');
    
else
    tempdir = dir(overlayFile);
    assert(~isempty(tempdir), 'Cannot find the overlay file: %s.', overlayFile);
    
    thePath = tempdir.folder;
    theFn = tempdir.name;
    
end

% the full path to the overlay file
overlayFile = fullfile(thePath, theFn);


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