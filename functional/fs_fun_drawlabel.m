function fs_fun_drawlabel(project, analysisName, contrastName, siglevel, extraLabelInfo)
% fs_fun_drawlabel(project, analysisName, contrastName, siglevel, extraLabelInfo)
% This function use FreeSurfer ("tksurfer") to draw labels.
%
% Inputs: 
%    project           <structure> or <string> or <cell of string>
%                      <structure> matlab structure for the project 
%                      (obtained from fs_fun_projectinfo);
%                      <string> subject code in $SUBJECTS_DIR;
%                      <cell of string> cell of subject codes in
%                      %SUBJECTS_DIR.
%    analysisName      <string> or <a cell of strings> the names of the
%                      analysis (i.e., the names of the analysis folders)
%    contrast_name     contrast name used glm (i.e., the names of contrast
%                      folders)
%    siglevel          significance level (default is f13 (.05))
%    extraLabelInfo    extra label information added to the label name
% Output:
%    a label saved in the label/ folder within $SUBJECTS_DIR
%
% Created by Haiyang Jin (10-Dec-2019)

if isstruct(project)
    % obtian the information about this bold type
    sessList = project.sessList;
    funcPath = project.funcPath;
elseif ischar(project)
    sessList = {project};
    funcPath = getenv('FUNCTIONALS_DIR');
end
nSess = numel(sessList);

if nargin < 4 || isempty(siglevel)
    siglevel = 'f13';
end
if nargin < 5 || isempty(extraLabelInfo)
    extraLabelInfo = '';
elseif ~strcmp(extraLabelInfo(end), '.')
    extraLabelInfo = [extraLabelInfo, '.'];
end

% convert analysisName to cell if it is string
if ischar(analysisName); analysisName = {analysisName}; end
nAnalysis = numel(analysisName);

%% Draw labels for all participants for both hemispheres

for iSess = 1:nSess
    
    thisSess = sessList{iSess};
    subjCode = fs_subjcode(thisSess, project.funcPath);
    
    for iAna = 1:nAnalysis
        
        thisAna = analysisName{iAna};
        hemi = fs_hemi(thisAna);
        
        sigFile = fullfile(project.funcPath, thisSess, 'bold',...
            thisAna, contrastName, 'sig.nii.gz');
        
        labelName = sprintf('roi.%s.%s.%s.%slabel', ...
            hemi, siglevel, contrastName, extraLabelInfo);
        
        % draw labels manually with FreeSurfer
        fv_drawlabel(subjCode, hemi, sigFile, labelName);
        
    end
    
end