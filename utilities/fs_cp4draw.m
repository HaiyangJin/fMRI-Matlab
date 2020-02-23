function fs_cp4draw(project, targetPath, analysisList, contrastList)
% This function copy the files necessary for drawing labels later.
%
% Inputs:
%     project          <structure> created by fs_fun_project.
%     targetPath       <string> the target path where the project will be
%                      copied to
%     analysisList     <string> or <cell of strings> the list of analysis
%                      name(s); it equals to the parent directory of
%                      funcPath.
%     contrastList     <string> or <cell of strings> the list of the
%                      contrast name(s).
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

structPath = project.structPath;
[~, structFolder] = fileparts(structPath);
funcPath = project.funcPath;
[~, funcFolder] = fileparts(funcPath);

surfFiles = {'*h.inflated', '*h.orig', '*h.curv', '*h.white', '*h.pial'};

% copy the analysis folders in funcPath
cellfun(@fs_copyfile, fullfile(funcPath, analysisList), ...
    fullfile(targetPath, funcFolder, analysisList));

for iSess = 1: project.nSess
    
    % functional data
    thisSess = project.sessList{iSess};
    
    tempBold = fullfile(thisSess, 'bold');
    
    [tempAna, tempCon] = ndgrid(analysisList, contrastList);
   
    % copy all the contrast folders
    cellfun(@(x, y) fs_copyfile(fullfile(funcPath, tempBold, x, y), ...
        fullfile(targetPath, funcFolder, tempBold, x, y)), tempAna, tempCon, ...
        'uni', false);
    
    % subjectname
    fs_copyfile(fullfile(funcPath, thisSess, 'subjectname'), ...
        fullfile(targetPath, funcFolder, thisSess));
    
    % structural data
    thisSubj = fs_subjcode(thisSess, funcPath);
    
    tempSurf = fullfile(thisSubj, 'surf');
    tempLabel = fullfile(thisSubj, 'label');
    tempOrig = fullfile(thisSubj, 'mri');
    
    cellfun(@(x) fs_copyfile(fullfile(structPath, tempSurf, x), ...
        fullfile(targetPath, structFolder, tempSurf)), surfFiles, 'uni', false);
    fs_copyfile(fullfile(structPath, tempLabel, '*h.aparc.annot'), ...
        fullfile(targetPath, structFolder, tempLabel));
    fs_copyfile(fullfile(structPath, tempOrig, 'orig.mgz'), ...
        fullfile(targetPath, structFolder, tempOrig));
    fs_copyfile(fullfile(structPath, tempOrig, 'transforms', 'talairach.xfm'), ...
        fullfile(targetPath, structFolder, tempOrig, 'transforms'));
    
end

end
