function hcp_cpfsf(subjCode, fsfPath)
% hcp_cpfsf(subjCode, fsfPath)
%
% This function copies *.fsf to run folders.
%
% For the first level *.fsf, the template fsf has to END with "_level1.fsf".
% By default, the char before "_level1.fsf" (with additional "*") will be 
% used to identify all the runs (via hcp_runlist) and fsf will be copied to
% these runs.
%
% For the second level *.fsf, the template fsf has to START with "level2".
% The full filename in the template fsf (without '.fsf') will be used to 
% create a folder within 'Results/' folder and the template will be copied 
% there. 
%
% Inputs:
%    subjCode      <string> subject code.
%    fsfPath       <str> where the template *.fsf are. The default is
%                   'fsf_templates' folder within HCP project directory.
%    
% Output:
%    fsf files in the desired folders. 
%
% Created by Haiyang Jin (2021-10-08)

if ~exist('fsfPath', 'var') || isempty(fsfPath)
    fsfPath = fullfile(hcp_dir, 'fsf_templates');
end
assert(logical(exist(fsfPath, 'dir')), 'Cannot find the directory: \n%s', fsfPath);
fsfdir = dir(fullfile(fsfPath, '*.fsf'));

fprintf('\nThe available fsf files (for %s) are: \n%s', subjCode, sprintf('%s \n', fsfdir.name));

nfsf = length(fsfdir);

for ifsf = 1:nfsf
    % the source file
    thefsf = fsfdir(ifsf).name;
    thesource = fullfile(fsfdir(ifsf).folder, thefsf); 
    
    if endsWith(thefsf, '_level1.fsf')
        % target file list
        runlist = hcp_runlist(subjCode, [erase(thefsf, '_level1.fsf') '*']);
        trgfiles = cellfun(@(x) [x '_hp200_s4_level1.fsf'], runlist, 'uni', false);
        
        cellfun(@(x) copyfile(thesource, x), fullfile(hcp_funcdir(subjCode), runlist, trgfiles)); 
  
    elseif startsWith(thefsf, 'level2')
        % make dir and copy fsf template there
        trgfolder = fullfile(hcp_funcdir(subjCode), erase(thefsf, '.fsf'));
        fm_mkdir(trgfolder); % make the new dir
        copyfile(thesource, fullfile(trgfolder, [erase(thefsf, '.fsf') '_hp200_s4_level2.fsf']));
        
    else
        warning(['Cannot identify which level the fsf file (%s) is for.\n' ...
            'Level 1 fsf has to end with "_level1.fsf".\n' ...
            'Level 2 fsf has to start with "level2".'], thefsf);
    end
    
end

end