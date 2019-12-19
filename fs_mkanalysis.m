function analysisList = fs_mkanalysis(funcRunType, boldext, nConditions, ...
    runFile_list, refDura, hemis, smooth, nSkip, TR)
% This function run mkanalysis-sess in FreeSurfer
%
% Inputs:
%    funcRunName        'main' or 'loc'
%    boldext            the extension of bold data ('self', 'fs', 'fsavg')
%    nConditions        number of conditions (excluded fixation)
%    runFile_list       run filenames (e.g., loc.txt)
%    refDura            durations of the reference condition (the total
%                       duration of one "block" or one "trial"
%    hemis              'lh', 'rh' (and 'mni')
%    smooth             smooth of data (double)
%    nSkip              number of TRs to be skipped at the run start
%    TR                 duration of one TR
% Output:
%    analysisList       a cell of all analysis names
%    run mkanalysis-sess in FreeSurfer
%
% Created by Haiyang Jin (19/12/2019)

if strcmp(boldext(1), '_')
    boldext = ['_' boldext];
end

if nargin < 6 || isempty(hemis)
    hemis = {'lh', 'rh', 'mni'};
elseif ischar(hemis)
    hemis = {hemis};
end
nHemi = numel(hemis);

if nargin < 7 || isempty(smooth)
    smooth = 0;
end

if nargin < 8 || isempty(nSkip)
    nSkip = 0;
end

if nargin < 9 || isempty(TR)
    TR = .75;
end


if ischar(runFile_list)
    runFile_list = {runFile_list};
end
nRunFile = numel(runFile_list);

% empty cell for saving analysis names
analysisList = cell(nRunFile, nHemi);

% the template for the analysis
if strcmp(boldext, '_self')
    template = 'self';
elseif ismember(boldext, {'fs', 'fsavg'})
    template = 'fsaverage';
end

% the paradigm filename
par_file = [funcRunType '.par'];


for iRun = 1:nRunFile
    
    thisRunFile = runFile_list{iRun};
    runCode = regexp(thisRunFile,'\d*','Match'); % run number
    if isempty(runCode)
        runCode = '';
    else
        runCode = runCode{1};
    end
    
    for iHemi = 1:nHemi
        
        % analysis name
        hemi = hemis{iHemi};
        analysisName = sprintf('%s_sm%d%s%s.%s', funcRunType, smooth, boldext, runCode, hemi);
        
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
            analysisName, hemiInfo, smooth, par_file, ...
            nConditions, nSkip, TR, thisRunFile,...
            refDura);
        
        system(fscmd_analysis)
        
    end
    
end
