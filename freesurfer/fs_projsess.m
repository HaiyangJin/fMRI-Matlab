function fscmd = fs_projsess(sessList, projFile, template, smooth, runList, hemi, funcPath)
% fscmd = fs_projsess(sessList, projFile, [template = 'fsaverage', smooth = 0,
%                     runList = [allruns], hemi = {'lh', 'rh'}, funcPath])
%
% This function projects the preprocessed functional (voxelwise) data for
% that whole session to fsaverage or self surface. Then FWHM smoothing is
% applied if needed. The additional output (compared with fs_projfunc.m and
% fs_projmask.m) files are (bold/masks/):
%     brain.[template].?h.pr.nii.gz
%
% Inputs:
%     sessList         <string> session code (list) in funcPath.
%     projFile         <string> the name of the to-be-projected file
%                       (i.e., the preprocessed functional data).
%                       [do not need to include '.nii.gz'.]
%     template         <string> 'fsaverage' or 'self'. fsaverage is the default.
%     smooth           <integer> smoothing with FWHM.
%     runList          <cell of strings> a list of run folder names, OR
%                      <string> the name of the run file. All runs are
%                      processed by default.
%     hemi             <string> which hemisphere. 'lh' (default) or 'rh'.
%     funcPath         <string> the full path to the functional folder.
%
% Output:
%     fscmd            <cell of strings> FreeSurfer commands used here.
%
% Created by Haiyang Jin (7-Apr-2020)

% name of the preprocessed data file.
projBasename = erase(projFile, '.nii.gz');
projFile = [projBasename '.nii.gz'];

if nargin < 3 || isempty(template)
    template = 'fsaverage';
    warning('The template was not specified and fsaverage will be used by default.');
elseif ~ismember(template, {'fsaverage', 'self'})
    error('The template has to be ''fsaverage'' or ''self'' (not ''%s'').', template);
end

if nargin < 4 || isempty(smooth)
    smooth = 0;
end

if nargin < 6 || isempty(hemi)
    hemi = {'lh', 'rh'};
end

if nargin < 7 || isempty(funcPath)
    funcPath = getenv('FUNCTIONALS_DIR');
end

if ischar(sessList)
    sessList = {sessList};
end
nSess = numel(sessList);

% empty cell for saving FreeSurfer commands
fscmd = cell(3, nSess);

% project data for each session separately
for iSess = 1:nSess
    
    % this session code
    thisSess = sessList{iSess};
    
    % the bold path
    boldPath = fullfile(funcPath, thisSess, 'bold');
    % the list of all runs
    runListAll = fs_runlist(boldPath);
    
    if nargin < 5 || isempty(runList)
        % run the analysis for all the runs
        runList = runListAll;
    elseif ischar(runList)
        % get the list of run folder names
        runList = fs_readtext(fullfile(boldPath, runList));
    end
    
    % all the combinations of hemispheres and runs
    [hemis, runs] = ndgrid(hemi, runList);
    
    %% Project masks for all runs
    fscmd1 = cellfun(@(x, y) fs_projmask(thisSess, x, template, y, funcPath), ...
        runs(:), hemis(:), 'uni', false);
    fscmd{1, iSess} = vertcat(fscmd1{:});
    
    %% Project functional data for all runs
    fscmd2 = cellfun(@(x, y) fs_projfunc(thisSess, projFile, x, template, y, ...
        smooth, funcPath), runs(:), hemis(:), 'uni', false);
    fscmd{2, iSess} = vertcat(fscmd2{:});
    
    %% Create the mean masks of all runs if all runs are projected
    if all(ismember(runList, runListAll))
        fscmd3 = fs_sessmeanmask(thisSess, template, funcPath);
        fscmd{3, iSess} = fscmd3;
    end
    
    %% save the FreeSurfer commands as one column
    fscmd = vertcat(fscmd{:});
    
end  % iSess

end  % function ends