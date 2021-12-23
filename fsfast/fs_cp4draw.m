function fs_cp4draw(sessList, targetPath, analysisList, contrastList, funcDir, struDir)
% fs_cp4draw(sessList, targetPath, analysisList, contrastList, funcDir, structDir)
%
% This function copy the files necessary for drawing labels later.
%
% Inputs:
%     sessList         <cell of strings> session codes in $FUNCTIONALS_DIR.
%     targetPath       <string> the target path where the project will be
%                       copied to
%     analysisList     <string> or <cell of strings> the list of analysis
%                       name(s); it equals to the parent directory of
%                       funcDir.
%     contrastList     <string> or <cell of strings> the list of the
%                       contrast name(s).
%     funcDir         <string> the full path to the functional folder.
%     struDir       <string> the full path to the subjects folder.
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
%     funcDir/sessCode/bold/analysisName/contrastNames
%
%     funcDir/sessCode/subjectname
%
%     funcDir/analysisname
%
% Created by Haiyang Jin (10-Feb-2020)

if nargin < 5 || isempty(funcDir)
    funcDir = getenv('FUNCTIONALS_DIR');
end

if nargin < 6 || isempty(struDir)
    struDir = getenv('SUBJECTS_DIR');
end

[~, structFolder] = fileparts(struDir);
[~, funcFolder] = fileparts(funcDir);

surfFiles = {'*h.inflated', '*h.orig', '*h.curv', '*h.white', '*h.pial'};

% copy the analysis folders in funcDir
cellfun(@fm_copyfile, fullfile(funcDir, analysisList), ...
    fullfile(targetPath, funcFolder, analysisList));

nSess = numel(sessList);
for iSess = 1: nSess
    
    % functional data
    thisSess = sessList{iSess};
    
    tempBold = fullfile(thisSess, 'bold');
    
    [tempAna, tempCon] = ndgrid(analysisList, contrastList);
   
    % copy all the contrast folders
    cellfun(@(x, y) fm_copyfile(fullfile(funcDir, tempBold, x, y), ...
        fullfile(targetPath, funcFolder, tempBold, x, y)), tempAna, tempCon, ...
        'uni', false);
    
    % subjectname
    fm_copyfile(fullfile(funcDir, thisSess, 'subjectname'), ...
        fullfile(targetPath, funcFolder, thisSess));
    
    % structural data
    thisSubj = fs_subjcode(thisSess);
    
    tempSurf = fullfile(thisSubj, 'surf');
    tempLabel = fullfile(thisSubj, 'label');
    tempOrig = fullfile(thisSubj, 'mri');
    
    cellfun(@(x) fm_copyfile(fullfile(struDir, tempSurf, x), ...
        fullfile(targetPath, structFolder, tempSurf)), surfFiles, 'uni', false);
    fm_copyfile(fullfile(struDir, tempLabel, '*h.aparc.annot'), ...
        fullfile(targetPath, structFolder, tempLabel));
    fm_copyfile(fullfile(struDir, tempOrig, 'orig.mgz'), ...
        fullfile(targetPath, structFolder, tempOrig));
    fm_copyfile(fullfile(struDir, tempOrig, 'transforms', 'talairach.xfm'), ...
        fullfile(targetPath, structFolder, tempOrig, 'transforms'));
    
end

end
