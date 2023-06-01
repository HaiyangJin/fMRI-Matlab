function Setup_fMRI_Matlab
% This function adds the necessary folders to Matlab path.

dirList = dir;
dirList([dirList.isdir]==0) = []; 
dirList(cellfun(@(x) startsWith(x, '.'), {dirList.name})) = []; 
dirList(ismember({dirList.name}, {'documents', 'reflabels'})) = [];

cellfun(@(x) addpath(genpath(x)), {dirList.name});

end