function fs_fun_screenshot_label(projStr, labelList, whichOverlay, output_path)
% This function gets the screenshots of labels with overlays.
%
% Inputs:
%    projStr           the proejct structure (e.g., FW)
%    labelList         a list of label names
%    whichOverlay      show overlay of the contrast of which label
%    output_path       where the labels to be saved
% Output:
%    screenshots in the folder
%
% Created by Haiyang Jin (10/12/2019)

if nargin < 3 || isempty(whichOverlay)
    whichOverlay = 0;  % do not show overlay by default
end
if nargin < 4 || isempty(output_path)
    output_path = '';
end

% number of labels
nLabels = size(labelList, 1);

% functional information about the structure
subjList = projStr.subjList;
nSubj = projStr.nSubj;
boldext = projStr.boldext;

f_single = waitbar(0, 'Generating screenshots for labels...');

for iLabel = 1:nLabels
    
    theLabel = labelList(iLabel, :);
    [hemi, nHemi] = fs_hemi_multi(theLabel);
    
    % move to next loop if the labels are not for the same hemisphere
    if nHemi ~= 1
        continue;
    end
    
    % determine which label and which label to show
    if numel(theLabel) == 1
        whichLabel = 1;
        whichContrast = 1;
    elseif numel(theLabel) > 1
        if ~whichOverlay
            whichLabel = 1;
            whichContrast = 0;
        else
            whichLabel = whichOverlay;
            whichContrast = whichOverlay;
        end
    end
    
    % get the contrast name from the label name
    labelName = theLabel{whichLabel};
    conStrPosition = strfind(labelName, '.');
    theContrast = labelName(conStrPosition(3)+1:conStrPosition(4)-1);
    
    for iSubj = 1:nSubj
        
        % this subject code
        thisBoldSubj = subjList{iSubj};  % bold subjCode
        subjCode = fs_subjcode(thisBoldSubj, projStr.fMRI); % FS subjCode
        
        % waitbar
        progress = ((iLabel-1) * nSubj + iSubj) / (nLabels * nSubj);
        wait_msg = sprintf('Label: %s  SubjCode: %s \n%0.2f%% finished...', ...
            strrep(labelName, '_', '\_'), strrep(subjCode, '_', '\_'), progress*100);
        waitbar(progress, f_single, wait_msg);
        
        % other information for screenshots
        analysis = sprintf('loc_%s.%s', boldext, hemi); % analysis name
        file_overlay = fullfile(projStr.fMRI, thisBoldSubj, 'bold',...
            analysis, theContrast, 'sig.nii.gz'); % the overlay file
        
        % skip if the overlay file is not available
        if ~whichContrast
            file_overlay = '';
        elseif ~exist(file_overlay, 'file')
            continue
        end
            
        % create the screenshot
        fs_screenshot_label(subjCode, theLabel, output_path, file_overlay, whichContrast);

    end
    
end

close(f_single);

