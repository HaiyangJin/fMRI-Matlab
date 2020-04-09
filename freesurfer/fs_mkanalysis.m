function [analysisList, fscmd] = fs_mkanalysis(funcRunType, template, nConditions, ...
    runFilename, refDura, TR, hemis, smooth, nSkip, anaExtra)
% [analysisList, fscmd] = fs_mkanalysis(funcRunType, template, nConditions, ...
%    runFilename, refDura, TR, hemis, smooth, nSkip, anaExtra)
%
% This function runs mkanalysis-sess in FreeSurfer.
%
% Inputs:
%     funcRunName        <string> 'main' or 'loc'
%     template           <string> 'fsaverage' or 'self'.
%     nConditions        <integer> number of conditions (excluded fixation).
%     runFilename        <string> or <cell of string> run filenames.
%     refDura            <numeric> durations of the reference condition.
%                         (the total duration of one "block" or one "trial")
%     TR                 <numeric> duration of one TR.
%     hemis              <cell of strings> or <string> 'lh', 'rh' (and 'mni')
%     smooth             <numeric> smoothing (FWHM).
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
% nCond = 8;
% runFilename = 'run_main.txt';
% refDura = 16;  % secs
% hemis = {'lh', 'rh'};
% smooth = 5;
% nSkip = 0;  % TRs
% TR = 2;  % secs
% anaExtra = 'E1';
% % make analysis
% anaList = fs_mkanalysis('main', template, nCond, runFilename, ...
%     refDura, TR, hemis, smooth, nSkip, anaExtra);
%
% Next step: fs_mkcontrast.m
%
% Created by Haiyang Jin (19-Dec-2019)

if ~ismember(template, {'fsaverage', 'self'})
    error('The template has to be ''fsaverage'' or ''self'' (not ''%s'').', template);
end

if nargin < 7 || isempty(hemis)
    hemis = {'lh', 'rh', 'mni'};
elseif ischar(hemis)
    hemis = {hemis};
end
nHemi = numel(hemis);

if nargin < 8 || isempty(smooth)
    smooth = 0;
end

if nargin < 9 || isempty(nSkip)
    nSkip = 0;
end

if nargin < 10 || isempty(anaExtra)
    anaExtra = '';
elseif ~startsWith(anaExtra, '_')
    anaExtra = [anaExtra '_'];
end

if ischar(runFilename)
    runFilename = {runFilename};
end
nRunFile = numel(runFilename);

% empty cell for saving analysis names
analysisList = cell(nRunFile, nHemi);

% the paradigm filename
parFile = [funcRunType '.par'];

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
            funcRunType, smooth, anaExtra, template, runCode, hemi);
        
        % save the analysis names into the cell
        analysisList(iRun, iHemi) = {analysisName};
        
        switch hemi
            case {'lh', 'rh'}
                hemiInfo = sprintf(' -surface %s %s', template, hemi);
            case 'mni'
                hemiInfo = ' -mni305 1';
        end
        
        % create the commands
        fscmd_analysis = sprintf(['mkanalysis-sess -analysis %s %s -fwhm %d -paradigm %s '...
            '-event-related -nconditions %d -nskip %d -TR %d -runlistfile %s '...
            '-refeventdur %d '...
            '-mcextreg -gammafit 2.25 1.25 -polyfit 2 -fsd bold -per-run -force'], ...
            analysisName, hemiInfo, smooth, parFile, ...
            nConditions, nSkip, TR, thisRunFile,...
            refDura);
        fscmd{iRun, iHemi} = fscmd_analysis;
        isnotok = system(fscmd_analysis);
        if isnotok
            error('Command (%s) failed.', fscmd_analysis);
        end
        
    end  % iHemi
    
end  % iRun

% save the FreeSurfer commands as one column
fscmd = vertcat(fscmd(:));

end