function fscmd = fs_drawlabel(sessList, anaList, conList, fthresh, extraLabelInfo, runcmd, funcPath)
% fscmd = fs_drawlabel(sessList, anaList, conList, fthresh, extraLabelInfo, runcmd, funcPath)
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
%    fthresh        <numeric> significance level (default is 2 (.01)).
%    extraLabelInfo  <string> extra label information added to the end
%                     of the label name.
%    funcPath       <string> the full path to the functional folder.
%    runcmd         <logical> 1: run FreeSurfer commands; 0: do not run
%                    but only output FreeSurfer commands. 
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

if ~exist('fthresh', 'var') || isempty(fthresh)
    fthresh = 2; % p < .01
end
if ~exist('extraLabelInfo', 'var') || isempty(extraLabelInfo)
    extraLabelInfo = '';
elseif ~strcmp(extraLabelInfo(end), '.')
    extraLabelInfo = [extraLabelInfo, '.'];
end

if ~exist('runcmd', 'var') || isempty(runcmd)
    runcmd = 1;
end

if ~exist('funcPath', 'var') || isempty(funcPath)
    funcPath = getenv('FUNCTIONALS_DIR');
end


%% Draw labels for all participants for both hemispheres
fscmdCell = cell(nSess, nAna, nCon);
for iAna = 1:nAna
    
    thisAna = anaList{iAna};
    hemi = fs_2hemi(thisAna);
    
    for iSess = 1:nSess
        
        thisSess = sessList{iSess};
        subjCode = fs_subjcode(thisSess, funcPath);
        
        
        for iCon = 1:nCon
            
            thisCon = conList{iCon};
            
            sigFile = fullfile(funcPath, thisSess, 'bold',...
                thisAna, thisCon, 'sig.nii.gz');
            
            labelName = sprintf('roi.%s.f%d.%s.%slabel', ...
                hemi, fthresh*10, thisCon, extraLabelInfo);
            
            % draw labels manually with FreeSurfer
            fscmdCell{iSess, iAna, iCon} = fv_drawlabel(subjCode, thisAna, sigFile, labelName, fthresh, runcmd);
            
        end  % iCon
    end  % iSess
end  % iAna


% make the FreeSurfer commands to one role
fscmd = fscmdCell(:);

end