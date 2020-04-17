function [anaList, fscmd] = fs_mkanalysis(runType, template, smooth, ...
    TR, runFilename, nConditions, refDura, hemis, stc, nSkip, anaExtra, runcmd)
%[anaList, fscmd] = fs_mkanalysis(runType, template, smooth, ...
%   TR, runFilename, nConditions, refDura, [hemis={'lh','rh','mni'}, stc='', ...
%   nSkip=0, anaExtra='', runcmd=1])
%
% This function runs mkanalysis-sess in FreeSurfer.
%
% Inputs:
%    runType            <string> 'main' or 'loc'.
%    template           <string> 'fsaverage' or 'self'.
%    smooth             <numeric> smoothing (FWHM).
%    TR                 <numeric> duration of one TR (seconds).
%    runFilename        <string> or <cell of string> run filenames.
%    nConditions        <integer> number of conditions (excluded fixation).
%    refDura            <numeric> durations of the reference condition.
%                        (the total duration of one "block" or one "trial")
%    hemis              <cell string> or <string> 'lh', 'rh' (and
%                        'mni' or 'mni1').
%    stc                <string> slice-timing corretion. The argument
%                        strings for -stc. [siemens, up, down, odd, even].
%    nSkip              <integer> number of TRs to be skipped at the run
%                        start.
%    anaExtra           <string> extra strings to be added to the
%                        analysis name.
%    runcmd             <logical> whether run the fscmd in FreeSufer (i.e.,
%                        make contrasts in FreeSurfer). 1: run fscmd
%                        [default]; 0: do not run fscmds and only output
%                        conStruct and fscmd.
%
% Output:
%    anaList            <cell strings> a cell of all analysis names.
%    fscmd              <cell strings> FreeSurfer commands used in the
%                        current session.
%    run mkanalysis-sess in FreeSurfer.
%
% Example:
% smooth = 5;
% TR = 2;  % secs
% runFilename = 'run_main.txt';
% nCond = 8;
% refDura = 16;  % secs
% hemis = {'lh', 'rh'};
% stc = '';
% nSkip = 0;  % TRs
% anaExtra = 'E1';
% % make analysis
% [anaList, fscmd] = fs_mkanalysis('main', 'fsaverage', smooth, ...
%     TR, runFilename, nConditions, refDura, hemis, stc, nSkip, anaExtra)
%
% Next step: fs_mkcontrast.m
%
% Created by Haiyang Jin (19-Dec-2019)

if ~ismember(template, {'fsaverage', 'self'})
    error('The template has to be ''fsaverage'' or ''self'' (not ''%s'').', template);
end

if ~exist('hemis', 'var') || isempty(hemis)
    hemis = {'lh', 'rh', 'mni'};
elseif ischar(hemis)
    hemis = {hemis};
end
nHemi = numel(hemis);

if ~exist('stcInfo', 'var') || isempty(stc)
    stcInfo = '';
else
    stcInfo = sprintf(' -stc %s', stc);
end

if ~exist('nSkip', 'var') || isempty(nSkip)
    nSkip = 0;
end

if ~exist('anaExtra', 'var') || isempty(anaExtra)
    anaExtra = '';
elseif ~startsWith(anaExtra, '_')
    anaExtra = [anaExtra '_'];
end

if ~exist('runcmd', 'var') || isempty(runcmd)
    runcmd = 1;
end

if ischar(runFilename)
    runFilename = {runFilename};
end
nRunFile = numel(runFilename);

% empty cell for saving analysis names
anaList = cell(nRunFile, nHemi);

% the paradigm filename
parFile = [runType '.par'];

% empty cell for saving FreeSurfer commands
fscmd = cell(nRunFile, nHemi);

for iRun = 1:nRunFile
    
    thisRunFile = runFilename{iRun};
    runCode = regexp(thisRunFile,'\d*','Match'); % run number
    if isempty(runCode)
        runCode = '';
    else
        runCode = runCode{1};
    end
    
    for iHemi = 1:nHemi
        
        % analysis name
        hemi = hemis{iHemi};
        analysisName = sprintf('%s_sm%d_%s%s%s.%s', ...
            runType, smooth, anaExtra, template, runCode, hemi);
        
        % save the analysis names into the cell
        anaList(iRun, iHemi) = {analysisName};
        
        switch hemi
            case {'lh', 'rh'}
                hemiInfo = sprintf(' -surface %s %s', template, hemi);
            case {'mni', 'mni2'}
                hemiInfo = ' -mni305 2';
            case 'mni1'
                hemiInfo = ' -mni305 1';
        end
                
        % create the FreeSurfer command
        thisfscmd = sprintf(['mkanalysis-sess -analysis %s'...
            '%s -fwhm %d%s -fsd bold -per-run '... % preprocessing
            '-event-related -paradigm %s -TR %d '...  % basic design arguments
            '-nconditions %d -gammafit 2.25 1.25 -refeventdur %d '... % event-related design arguments
            '-polyfit 2 -nskip %d -mcextreg ' ... % noise, drift, and temporal filtering options
            '-runlistfile %s -force'], ... % other options
            analysisName, ... 
            hemiInfo, smooth, stcInfo, ... % preprocessing
            parFile, TR, ... % basic design
            nConditions, refDura, ... % event-related
            nSkip, thisRunFile...
            );
        fscmd{iRun, iHemi} = thisfscmd;
        
    end  % iHemi
    
end  % iRun

% save the FreeSurfer commands as one column
fscmd = fscmd(:);

% run or not running the fscmd
if runcmd
    isnotok = cellfun(@system, fscmd);
else
    isnotok = zeros(size(fscmd));
end

% finishing message
if any(isnotok)
    warning('Some FreeSurfer commands (mkanalysis-sess) failed.');
elseif runcmd
    fprintf('\nmkanalysis-sess finished with error.\n');
end

end