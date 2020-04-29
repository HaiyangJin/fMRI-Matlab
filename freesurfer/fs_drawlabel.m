function fscmd = fs_drawlabel(sessList, anaList, conList, fthresh, extraLabelInfo, funcPath)
% fscmd = fs_drawlabel(sessList, anaList, conList, fthresh, extraLabelInfo, funcPath)
%
% This function use FreeSurfer ("tksurfer") to draw labels.
%
% Inputs:
%    sessList       <string> session code in $FUNCTIONALS_DIR;
%                   <cell of string> cell of session codes in
%                    %SUBJECTS_DIR.
%    anaList        <string> or <a cell of strings> the names of the
%                    analysis (i.e., the names of the analysis folders).
%    conList        <string> contrast name used glm (i.e., the names of
%                    contrast folders).
%    fthresh        <numeric> significance level (default is f13 (.05)).
%    extraLabelInfo  <string> extra label information added to the end
%                     of the label name.
%    funcPath       <string> the full path to the functional folder.
%
% Output:
%    fscmd          <string> FreeSurfer commands used.
%    a label saved in the label/ folder within $SUBJECTS_DIR
%
% Created by Haiyang Jin (10-Dec-2019)

% convert to cell if it is char
if ischar(sessList); sessList = {sessList}; end
nSess = numel(sessList);
if ischar(anaList); anaList = {anaList}; end
nAna = numel(anaList);
if ischar(conList); conList = {conList}; end
nCon = numel(conList);

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

%% Draw labels for all participants for both hemispheres
fscmdCell = cell(nSess, nAna, nCon);
for iSess = 1:nSess
    
    thisSess = sessList{iSess};
    subjCode = fs_subjcode(thisSess, funcPath);
    
    for iAna = 1:nAna
        
        thisAna = anaList{iAna};
        hemi = fs_2hemi(thisAna);
        
        for iCon = 1:nCon
            
            thisCon = conList{iCon};
            
            sigFile = fullfile(funcPath, thisSess, 'bold',...
                thisAna, thisCon, 'sig.nii.gz');
            
            labelName = sprintf('roi.%s.f%d.%s.%slabel', ...
                hemi, fthresh*10, thisCon, extraLabelInfo);
            
            % draw labels manually with FreeSurfer
            fscmdCell{iSess, iAna, iCon} = fv_drawlabel(subjCode, thisAna, sigFile, labelName, fthresh);
            
        end  % iCon
    end  % iAna
end  % iSess

% make the FreeSurfer commands to one role
fscmd = fscmdCell(:);

end