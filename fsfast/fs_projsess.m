function fscmd = fs_projsess(sessList, projFile, template, smooth, runInfo, hemi)
% fscmd = fs_projsess(sessList, projFile, [template = 'self', smooth = 5,
%                     runInfo = [allruns], hemi = {'lh', 'rh'}])
%
% This function projects the preprocessed functional (voxelwise) data for
% that whole session to fsaverage or self surface. Then FWHM smoothing is
% applied if needed. The additional output (compared with fs_projfunc.m and
% fs_projmask.m) files are (bold/masks/):
%     brain.[template].?h.pr.nii.gz
%
% Inputs:
%     sessList         <str> session code (list) in $FUNCTIONALS_DIR.
%     projFile         <str> the name of the to-be-projected file
%                       (i.e., the preprocessed functional data).
%                       [do not need to include '.nii.gz'.]
%     template         <str> 'fsaverage' or 'self'. fsaverage is the default.
%     smooth           <int> smoothing with FWHM.
%     runInfo          <cell str> a list of run folder names, OR
%                      <str> the name of the run file. All runs are
%                      processed by default.
%     hemi             <str> which hemisphere. 'lh' (default) or 'rh'.
%
% Output:
%     fscmd            <cell str> FreeSurfer commands used here.
%
% Created by Haiyang Jin (7-Apr-2020)

% name of the preprocessed data file.

projBasename = erase(projFile, '.nii.gz');
projFile = [projBasename '.nii.gz'];

if ~exist('template', 'var') || isempty(template)
    template = 'self';
    warning('The template was not specified and self will be used by default.');
elseif ~ismember(template, {'fsaverage', 'self'})
    error('The template has to be ''fsaverage'' or ''self'' (not ''%s'').', template);
end

if ~exist('smooth', 'var') || isempty(smooth)
    smooth = 5;
end

if ~exist('runInfo', 'var') || isempty(runInfo)
    runInfo = '';
end

if ~exist('hemi', 'var') || isempty(hemi)
    hemi = {'lh', 'rh'};
end

assert(~isempty(getenv('FUNCTIONALS_DIR')), ['Please set the functional ' ...
    'folder with fs_subjdir().']);

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
    
    % the list of all runs
    runListAll = fs_runlist(thisSess);
    runList = fs_runlist(thisSess, runInfo);
    
    % all the combinations of hemispheres and runs
    [hemis, runs] = ndgrid(hemi, runList);
    
    %% Project masks for all runs
    fscmd1 = cellfun(@(x, y) fs_projmask(thisSess, x, template, y), ...
        runs(:), hemis(:), 'uni', false);
    fscmd{1, iSess} = vertcat(fscmd1{:});
    
    %% Project functional data for all runs
    fscmd2 = cellfun(@(x, y) fs_projfunc(thisSess, projFile, x, template, y, ...
        smooth), runs(:), hemis(:), 'uni', false);
    fscmd{2, iSess} = vertcat(fscmd2{:});
    
    %% Create the mean masks of all runs if all runs are projected
    if all(ismember(runList, runListAll))
        fscmd3 = fs_sessmeanmask(thisSess, template);
        fscmd{3, iSess} = fscmd3;
    end
    
    %% save the FreeSurfer commands as one column
    fscmd = vertcat(fscmd{:});
    
end  % iSess

end  % function ends