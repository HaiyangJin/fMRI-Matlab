function [anaList, fscmd] = fs_mkanalysis(runType, template, smooth, ...
    TR, runFilename, nConditions, refDura, hemis, stc, nSkip, anaExtra)
%[anaList, fscmd] = fs_mkanalysis(runType, template, smooth, ...
%   TR, runFilename, nConditions, refDura, hemis, stc, nSkip, anaExtra)
%
% This function runs mkanalysis-sess in FreeSurfer.
%
% Inputs:
%     runType            <string> 'main' or 'loc'.
%     template           <string> 'fsaverage' or 'self'.
%     smooth             <numeric> smoothing (FWHM).
%     TR                 <numeric> duration of one TR (seconds).
%     runFilename        <string> or <cell of string> run filenames.
%     nConditions        <integer> number of conditions (excluded fixation).
%     refDura            <numeric> durations of the reference condition.
%                         (the total duration of one "block" or one "trial")
%     hemis              <cell of strings> or <string> 'lh', 'rh' (and
%                         'mni' or 'mni1').
%     stc                <string> slice-timing corretion. The argument
%                         strings for -stc. [siemens, up, down, odd, even].
%     nSkip              <integer> number of TRs to be skipped at the run
%                         start.
%     anaExtra           <string> extra strings to be added to the
%                         analysis name.
%
% Output:
%     analysisList       <cell of strings> a cell of all analysis names.
%     fscmd              <cell of strings> FreeSurfer commands used in the
%                         current session.
%     run mkanalysis-sess in FreeSurfer.
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

if nargin < 8 || isempty(hemis)
    hemis = {'lh', 'rh', 'mni'};
elseif ischar(hemis)
    hemis = {hemis};
end
nHemi = numel(hemis);

if nargin < 9 || isempty(stc)
    stcInfo = '';
else
    stcInfo = sprintf(' -stc %s', stc);
end

if nargin < 10 || isempty(nSkip)
    nSkip = 0;
end

if nargin < 11 || isempty(anaExtra)
    anaExtra = '';
elseif ~startsWith(anaExtra, '_')
    anaExtra = [anaExtra '_'];
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
        fscmd_analysis = sprintf(['mkanalysis-sess -analysis %s'...
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
        fscmd{iRun, iHemi} = fscmd_analysis;
        
        isnotok = system(fscmd_analysis);
        assert(~isnotok, 'Command (%s) failed.', fscmd_analysis);
        
    end  % iHemi
    
end  % iRun

% save the FreeSurfer commands as one column
fscmd = vertcat(fscmd(:));

end