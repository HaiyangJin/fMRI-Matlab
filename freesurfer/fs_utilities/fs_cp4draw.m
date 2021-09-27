function fs_cp4draw(sessList, targetPath, analysisList, contrastList, funcPath, structPath)
% fs_cp4draw(sessList, targetPath, analysisList, contrastList, funcPath, structPath)
%
% This function copy the files necessary for drawing labels later.
%
% Inputs:
%     sessList         <cell of strings> session codes in $FUNCTIONALS_DIR.
%     targetPath       <string> the target path where the project will be
%                       copied to
%     analysisList     <string> or <cell of strings> the list of analysis
%                       name(s); it equals to the parent directory of
%                       funcPath.
%     contrastList     <string> or <cell of strings> the list of the
%                       contrast name(s).
%     funcPath         <string> the full path to the functional folder.
%     structPath       <string> the full path to the subjects folder.
%
% Output:
%     the necessary files for drawing labels
%
%     $SUBJECTS_DIR/subjCode/
%           surf/?h.inflated
%           surf/?h.orig
%           surf/?h.curv
%           surf/?h.white
%           surf/?h.pial
%           label/?h.aparc.annot
%           mri/orig.mgz
%           mri/transforms/talairach.xfm
%
%     funcPath/sessCode/bold/analysisName/contrastNames
%
%     funcPath/sessCode/subjectname
%
%     funcPath/analysisname
%
% Created by Haiyang Jin (10-Feb-2020)

if nargin < 5 || isempty(funcPath)
    funcPath = getenv('FUNCTIONALS_DIR');
end

if nargin < 6 || isempty(structPath)
    funcPath = getenv('SUBJECTS_DIR');
end

[~, structFolder] = fileparts(structPath);
[~, funcFolder] = fileparts(funcPath);

surfFiles = {'*h.inflated', '*h.orig', '*h.curv', '*h.white', '*h.pial'};

% copy the analysis folders in funcPath
cellfun(@fm_copyfile, fullfile(funcPath, analysisList), ...
    fullfile(targetPath, funcFolder, analysisList));

nSess = numel(sessList);
for iSess = 1: nSess
    
    % functional data
    thisSess = sessList{iSess};
    
    tempBold = fullfile(thisSess, 'bold');
    
    [tempAna, tempCon] = ndgrid(analysisList, contrastList);
   
    % copy all the contrast folders
    cellfun(@(x, y) fm_copyfile(fullfile(funcPath, tempBold, x, y), ...
        fullfile(targetPath, funcFolder, tempBold, x, y)), tempAna, tempCon, ...
        'uni', false);
    
    % subjectname
    fm_copyfile(fullfile(funcPath, thisSess, 'subjectname'), ...
        fullfile(targetPath, funcFolder, thisSess));
    
    % structural data
    thisSubj = fs_subjcode(thisSess, funcPath);
    
    tempSurf = fullfile(thisSubj, 'surf');
    tempLabel = fullfile(thisSubj, 'label');
    tempOrig = fullfile(thisSubj, 'mri');
    
    cellfun(@(x) fm_copyfile(fullfile(structPath, tempSurf, x), ...
        fullfile(targetPath, structFolder, tempSurf)), surfFiles, 'uni', false);
    fm_copyfile(fullfile(structPath, tempLabel, '*h.aparc.annot'), ...
        fullfile(targetPath, structFolder, tempLabel));
    fm_copyfile(fullfile(structPath, tempOrig, 'orig.mgz'), ...
        fullfile(targetPath, structFolder, tempOrig));
    fm_copyfile(fullfile(structPath, tempOrig, 'transforms', 'talairach.xfm'), ...
        fullfile(targetPath, structFolder, tempOrig, 'transforms'));
    
end

end
