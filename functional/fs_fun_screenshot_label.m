function fs_fun_screenshot_label(projStr, labelList, output_path)
% This function gets the screenshots of labels with overlays.
%
% Inputs:
%    projStr           the proejct structure (e.g., FW)
%    labelList         a list of label names
%    output_path       where the labels to be saved
% Output:
%    screenshots in the folder
%
% Created by Haiyang Jin (10/12/2019)

if nargin < 3 || isempty(output_path)
    output_path = '';
end

% number of labels
nLabels = numel(labelList);

% functional information about the structure
subjList = projStr.subjList;
nSubj = projStr.nSubj;
boldext = projStr.boldext;

f_single = waitbar(0, 'Generating screenshots for labels...');

for iLabel = 1:nLabels
    
    thisLabel = labelList{iLabel};
    hemi = fs_hemi(thisLabel);
    
    % get the contrast name from the label name
    conStrPosition = strfind(thisLabel, '.');
    theContrast = thisLabel(conStrPosition(3)+1:conStrPosition(4)-1);
    
    for iSubj = 1:nSubj
        
        % this subject code
        thisBoldSubj = subjList{iSubj};  % bold subjCode
        subjCode = fs_subjcode(thisBoldSubj, projStr.fMRI); % FS subjCode
        
        % waitbar
        progress = ((iLabel-1) * nSubj + iSubj) / (nLabels * nSubj);
        wait_msg = sprintf('Label: %s  SubjCode: %s \n%0.2f%% finished...', ...
            strrep(thisLabel, '_', '\_'), strrep(subjCode, '_', '\_'), progress*100);
        waitbar(progress, f_single, wait_msg);
        
        % other information for screenshots
        analysis = sprintf('loc_%s.%s', boldext, hemi); % analysis name
        file_overlay = fullfile(projStr.fMRI, thisBoldSubj, 'bold',...
            analysis, theContrast, 'sig.nii.gz'); % the overlay file
        
        % skip if the overlay file is not available
        if ~exist(file_overlay, 'file')
            continue
        end
            
        % create the screenshot
        fs_screenshot_label(subjCode, thisLabel, output_path, file_overlay);

    end
    
end

close(f_single);

