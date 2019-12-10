function fs_fun_drawlabel(projStr, contrast_name, boldext, siglevel, extraLabelInfo)
% This function use FreeSurfer ("tksurfer") to draw labels.
%
% Inputs: 
%    projStr           matlab structure for the project (e.g.,fw_projectinfo).
%                      This is specific for each project.
%    contrast_name     contrast name used glm
%    boldext           bold extension, part of the ananlysis name (usually use 'self')
%    siglevel          significance level (default is f13 (.05))
%    extraLabelInfo    extra label information added to the label name
% Output:
%    a label saved in that label folder
%
% Created by Haiyang Jin (10/12/2019)

if nargin < 3 || isempty(boldext)
    boldext = '_self';
elseif ~strcmp(boldext(1), '_')
    boldext = ['_' boldext];
end
if nargin < 4 || isempty(siglevel)
    siglevel = 'f13';
end
if nargin < 5 || isempty(extraLabelInfo)
    extraLabelInfo = '';
elseif ~strcmp(extraLabelInfo(end), '.')
    extraLabelInfo = [extraLabelInfo, '.'];
end

% obtian the information about this bold type
subjList = projStr.subjList;
nSubj = projStr.nSubj;
hemis = projStr.hemis;

%% Draw labels for all participants for both hemispheres

for iSubj = 1:nSubj
    
    thisBoldSubj = subjList{iSubj};
    subjCode = fs_subjcode(thisBoldSubj, projStr.fMRI);
    
    for iHemi = 1:projStr.nHemi
        
        hemi = hemis{iHemi};
        
        file_sig = fullfile(projStr.fMRI, thisBoldSubj, 'bold',...
            ['loc' boldext '.' hemi], contrast_name, 'sig.nii.gz');
        
        labelname = sprintf('roi.%s.%s.%s.%slabel', ...
            hemi, siglevel, contrast_name, extraLabelInfo);
        
        % draw labels manually with FreeSurfer
        fs_drawlabel(subjCode, hemi, file_sig, labelname);
        
    end
    
end