function fs_fun_drawlabel(projStr, contrastName, siglevel, extraLabelInfo)
% This function use FreeSurfer ("tksurfer") to draw labels.
%
% Inputs: 
%    projStr           matlab structure for the project (obtained from fs_fun_projectinfo)
%                      This is specific for each project.
%    contrast_name     contrast name used glm
%    siglevel          significance level (default is f13 (.05))
%    extraLabelInfo    extra label information added to the label name
% Output:
%    a label saved in the label folder within $SUBJECTS_DIR
%
% Created by Haiyang Jin (10/12/2019)


if nargin < 3 || isempty(siglevel)
    siglevel = 'f13';
end
if nargin < 4 || isempty(extraLabelInfo)
    extraLabelInfo = '';
elseif ~strcmp(extraLabelInfo(end), '.')
    extraLabelInfo = [extraLabelInfo, '.'];
end

% obtian the information about this bold type
boldext = projStr.boldext;
sessList = projStr.subjList;
nSess = projStr.nSubj;
hemis = projStr.hemis;

%% Draw labels for all participants for both hemispheres

for iSess = 1:nSess
    
    thisSess = sessList{iSess};
    subjCode = fs_subjcode(thisSess, projStr.funcPath);
    
    for iHemi = 1:projStr.nHemi
        
        hemi = hemis{iHemi};
        
        sigFile = fullfile(projStr.funcPath, thisSess, 'bold',...
            ['loc' boldext '.' hemi], contrastName, 'sig.nii.gz');
        
        labelName = sprintf('roi.%s.%s.%s.%slabel', ...
            hemi, siglevel, contrastName, extraLabelInfo);
        
        % draw labels manually with FreeSurfer
        fs_drawlabel(subjCode, hemi, sigFile, labelName);
        
    end
    
end