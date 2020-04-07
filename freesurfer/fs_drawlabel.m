function fs_drawlabel(sessList, analysisName, contrastName, fthresh, extraLabelInfo, funcPath)
% fs_drawlabel(sessList, analysisName, contrastName, fthresh, extraLabelInfo, funcPath)
%
% This function use FreeSurfer ("tksurfer") to draw labels.
%
% Inputs: 
%    sessList          <string> session code in $FUNCTIONALS_DIR;
%                      <cell of string> cell of session codes in
%                      %SUBJECTS_DIR.
%    analysisName      <string> or <a cell of strings> the names of the
%                      analysis (i.e., the names of the analysis folders).
%    contrast_name     <string> contrast name used glm (i.e., the names of 
%                      contrast folders).
%    fthresh           <numeric> significance level (default is f13 (.05)).
%    extraLabelInfo    <string> extra label information added to the end 
%                      of the label name.
%    funcPath          <string> the full path to the functional folder.
%
% Output:
%    a label saved in the label/ folder within $SUBJECTS_DIR
%
% Created by Haiyang Jin (10-Dec-2019)

if ischar(sessList)
    sessList = {sessList};
end
nSess = numel(sessList);

if nargin < 4 || isempty(fthresh)
    fthresh = 2; % p < .01
end
if nargin < 5 || isempty(extraLabelInfo)
    extraLabelInfo = '';
elseif ~strcmp(extraLabelInfo(end), '.')
    extraLabelInfo = [extraLabelInfo, '.'];
end

if nargin < 6 || isempty(funcPath)
    funcPath = getenv('FUNCTIONALS_DIR');
end

% convert analysisName to cell if it is string
if ischar(analysisName); analysisName = {analysisName}; end
nAnalysis = numel(analysisName);

%% Draw labels for all participants for both hemispheres

for iSess = 1:nSess
    
    thisSess = sessList{iSess};
    subjCode = fs_subjcode(thisSess, funcPath);
    
    for iAna = 1:nAnalysis
        
        thisAna = analysisName{iAna};
        hemi = fs_hemi(thisAna);
        
        sigFile = fullfile(funcPath, thisSess, 'bold',...
            thisAna, contrastName, 'sig.nii.gz');
        
        labelName = sprintf('roi.%s.f%d.%s.%slabel', ...
            hemi, fthresh*10, contrastName, extraLabelInfo);
        
        % draw labels manually with FreeSurfer
        fv_drawlabel(subjCode, hemi, sigFile, labelName, fthresh);
        
    end
    
end