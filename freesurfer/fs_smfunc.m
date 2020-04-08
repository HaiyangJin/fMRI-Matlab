function [fscmd, isok] = fs_smfunc(sessList, smooth, runList, template, funcPath)
% [fscmd, isok] = fs_smfunc(sessList, [smooth = 5, runList = [allruns],
%                           template = 'fsaverage', funcPath])
%
% This function will smooth all the *.sm0* files to *.sm?.* accordingly.
%
% Inputs:
%    sessList         <string> session code (list) in funcPath.
%    smooth           <integer> smoothing with FWHM.
%    runList          <cell of strings> a list of run folder names, OR
%                     <string> the name of the run file. All runs are
%                      processed by default.
%    template         <string> 'fsaverage' or 'self'. fsaverage is the default.
%    funcPath         <string> the full path to the functional folder.
%
% Output:
%    fscmd            <cell of strings> FreeSurfer commands used here.
%    isok             <array of numbers> if fscmd is run successfully. [0
%                      denotes successfully; any positive numbers denote
%                      the commands failed; -1 denotes cannot find the
%                      unique unsmoothed data file].
%
% Created by Haiyang Jin (8-Apr-2020)

if ischar(sessList)
    sessList = {sessList};
end
nSess = numel(sessList);

if nargin < 2 || isempty(smooth)
    smooth = 5;
    warning('The default smooth of 5 (FWHM) is used.');
end

if nargin < 4 || isempty(template)
    template = 'fsaverage';
    warning('The template was not specified and fsaverage will be used by default.');
elseif ~ismember(template, {'fsaverage', 'self'})
    error('The template has to be ''fsaverage'' or ''self'' (not ''%s'').', template);
end

if nargin < 5 || isempty(funcPath)
    funcPath = getenv('FUNCTIONALS_DIR');
end

% hemispheres (not support mni305 now, but it is possible)
hemis = {'lh', 'rh'};
nHemi = numel(hemis);

% empty array for saving output
fscmd = cell(nSess, 1);
isok = cell(nSess, 1);

for iSess = 1:nSess
    
    % this session
    thisSess = sessList{iSess};
    trgSubj = fs_trgsubj(fs_subjcode(thisSess, funcPath), template);
    
    % the bold path
    boldPath = fullfile(funcPath, thisSess, 'bold');
    
    % run lists
    if nargin < 5 || isempty(runList)
        % run the analysis for all the runs
        runList = fs_runlist(boldPath);
    elseif ischar(runList)
        % get the list of run folder names from the run list file
        runList = fs_readtext(fullfile(boldPath, runList));
    end
    nRun = numel(runList);
    
    % empty array for saving output
    fscmdTemp = cell(nRun, nHemi);
    isokTemp = nan(nRun, nHemi);
    
    for iRun = 1:nRun
        
        % this run
        thisRun = runList{iRun};
        runPath = fullfile(boldPath, thisRun, filesep);
        
        for iHemi = 1:nHemi
            
            hemi = hemis{iHemi};
            sm0Dir = dir(fullfile(runPath, sprintf('*.sm0.%s.%s.nii.gz', template, hemi)));
            
            % throw warning if cannot find unsmooth files
            if numel(sm0Dir) ~= 1
                warning(['Cannot find the unique unsmoothed (*.sm0.*) file for \n'...
                    'session: %s; run: %s; hemi: %s; template: %s\n'], ...
                    thisSess, thisRun, hemi, template);
                
                isokTemp(iRun, iHemi) = -1; % some random number
                continue;
            end
            
            % unsmoothed filename
            sm0Fn = sm0Dir.name;
            % smoothed filename (output)
            smFn = strrep(sm0Dir.name, 'sm0', sprintf('sm%d', smooth));
            % mask filename
            maskFn = sprintf('brain.%s.%s.nii.gz', template, hemi);
            
            % create the commands in FreeSurfer
            fscmd1 = sprintf(['mris_fwhm --s %2$s --hemi %3$s --smooth-only '...
                '--i %1$s%4$s --fwhm %5$d --o %1$s%6$s '...
                '--mask %1$smasks/%7$s --no-detrend'], ...
                runPath, trgSubj, hemi, sm0Fn, smooth, smFn, maskFn);
            fscmdTemp{iRun, iHemi} = fscmd1;
            isokTemp(iRun, iHemi) = system(fscmd1);
            
        end  % iHemi
        
    end  % iRun
    fscmd{iSess, iHemi} = reshape(fscmdTemp, [], 1);
    isok{iSess, iHemi} = reshape(isokTemp, [], 1);
end % iSess

% save the output as one column
fscmd = vertcat(fscmd{:});
isok = vertcat(isok{:});

end