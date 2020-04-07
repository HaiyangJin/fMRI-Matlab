function fs_fun_screenshot_label(project, labelList, runType, template, ...
    outputPath, sm, whichOverlay, threshold, runNum)
% fs_fun_screenshot_label(project, labelList, outputPath, whichOverlay, locSmooth, threshold)
% This function gets the screenshots of labels with overlays.
%
% Inputs:
%     project           <structure> the proejct structure (created by 
%                        fs_functionals).
%     labelList         <cell of strings> a list of label names.
%     runType           <string> 'loc' or 'main'.
%     template          <string> 'fsaverage' or 'self'. fsaverage is the default.
%     outputPath        <string> where the labels to be saved.
%     sm                <string> smooth (FWHM).
%     whichOverlay      <integer> show overlay of the contrast of which
%                        label.
%     threshold         <numeric> 0.05, 0.1... or 1.3, 2, 3.
%     runNum            <numeric> the last part of run file's basename.
%                        [e.g. 1 in main1.txt].
%
% Output:
%     screenshots in the folder
%
% Created by Haiyang Jin (10-Dec-2019)

if nargin < 3
    runType = 'loc';
end

if nargin < 4 || isempty(template)
    template = 'fsaverage';
    warning('The template was not specified and fsaverage will be used by default.');
elseif ~ismember(template, {'fsaverage', 'self'})
    error('The template has to be ''fsaverage'' or ''self'' (not ''%s'').', template);
end

if nargin < 5
    outputPath = '';
end

if nargin < 6 || isempty(sm)
    sm = '';
elseif ~strcmp(sm(1), '_')
    sm = ['_' sm];
end

if nargin < 7 || isempty(whichOverlay)
    whichOverlay = 1; % show the overlay of the first label by default
end

if nargin < 8 || isempty(threshold)
    threshold = '';
end

if nargin < 9 || isempty(runNum)
    runNum = '';
elseif isnumeric(runNum)
    runNum = num2str(runNum);
end

% number of labels
nLabels = size(labelList, 1);

% functional information about the structure
sessList = project.sessList;
nSess = project.nSess;

waitHandle = waitbar(0, 'Generating screenshots for labels...');

for iLabel = 1:nLabels
    
    theLabel = labelList(iLabel, :);
    [hemi, nHemi] = fs_hemi_multi(theLabel);
    
    % move to next loop if the labels are not for the same hemisphere
    if nHemi ~= 1
        continue;
    end
    
    % get the contrast name from the label name
    if ~whichOverlay
        labelName = theLabel{1};
    else
        labelName = theLabel{whichOverlay};
    end
    theContrast = fs_label2contrast(labelName);
    
    
    for iSess = 1:nSess
        
        % this subject code
        thisSess = sessList{iSess};  % bold subjCode
        subjCode = fs_subjcode(thisSess, project.funcPath); % FS subjCode
        
        % waitbar
        progress = ((iLabel-1) * nSess + iSess) / (nLabels * nSess);
        waitMsg = sprintf('Label: %s  SubjCode: %s \n%0.2f%% finished...', ...
            strrep(labelName, '_', '\_'), strrep(subjCode, '_', '\_'), progress*100);
        waitbar(progress, waitHandle, waitMsg);
        
        % other information for screenshots
        analysis = sprintf('%s%s%s%s.%s', runType, sm, template, runNum, hemi); % analysis name
        overlayFile = fullfile(project.funcPath, thisSess, 'bold',...
            analysis, theContrast, 'sig.nii.gz'); % the overlay file
        
        % skip if the overlay file is not available
        if ~whichOverlay
            overlayFile = '';
        elseif ~exist(overlayFile, 'file')
            warning('Cannot find the overlay file: %s', overlayFile);
            continue
        end
        
        % create the screenshot
        fv_label(subjCode, theLabel, outputPath, overlayFile, threshold, template, '', 1);
        
    end
    
end

close(waitHandle);
end