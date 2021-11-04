function [anaList, fscmd] = fs_mkanalysis(runType, template, TR, ...
    runFilename, nConditions, refDura, varargin)
% [anaList, fscmd] = fs_mkanalysis(runType, template, TR, ...
%     runFilename, nConditions, refDura, varargin)
%
% This function runs mkanalysis-sess in FreeSurfer.
%
% Inputs:
%    runType            <str> 'main' or 'loc'.
%    template           <str> 'fsaverage' or 'self'.
%    TR                 <num> duration of one TR (seconds).
%    runFilename        <str> the run file which saves a list of run names.
%                    OR <cell str> a cell list of run names.
%    nConditions        <int> number of conditions (excluded fixation).
%    refDura            <num> durations of the reference condition.
%                        (the total duration of one "block" or one "trial")
%
% Varargin:
%    'smooth'           <num> smoothing (FWHM). Default is 0.
%    'hemis'            <cell str> or <str> 'lh', 'rh' (and
%                        'mni' or 'mni1'). Default is {'lh', 'rh', 'mni'}.
%    'stc'              <str> slice-timing corretion. The argument
%                        strings for -stc. [siemens, up, down, odd, even].
%                        Default is ''.
%    'nskip'            <int> number of TRs to be skipped at the run start.
%                        Default is 0.
%    'anaextra'         <str> extra strings to be added to the analysis
%                        name.
%    'runcmd'           <boo> whether run the fscmd in FreeSufer (i.e.,
%                        make contrasts in FreeSurfer). 1: run fscmd
%                        [default]; 0: do not run fscmds and only output
%                        conStruct and fscmd.
%
% Output:
%    anaList            <cell str> a cell of all analysis names.
%    fscmd              <cell str> FreeSurfer commands used in the
%                        current session.
%    run mkanalysis-sess in FreeSurfer.
%
% Example:
% TR = 2;  % secs
% runFilename = 'run_main.txt';
% nCond = 8;
% refDura = 16;  % secs
% % make analysis
% [anaList, fscmd] = fs_mkanalysis('main', 'fsaverage', TR, runFilename, ...
%    nCond, refDura)
%
% Created by Haiyang Jin (19-Dec-2019)
%
% See also:
% [fs_preproc;] fs_mkcontrast

if ~ismember(template, {'fsaverage', 'self'})
    error('The template has to be ''fsaverage'' or ''self'' (not ''%s'').', template);
end

defaultOpts = struct(...
    'smooth', 0, ...
    'hemis', {'lh', 'rh', 'mni'}, ...
    'stc', '', ...
    'nskip', 0, ...
    'anaextra', '', ...
    'runcmd', 1 ...
);

opts = fm_mergestruct(defaultOpts, varargin);

if ischar(opts.hemis)
    opts.hemis = {opts.hemis};
end
nHemi = numel(opts.hemis);

if isempty(opts.stc)
    stcInfo = '';
else
    stcInfo = sprintf(' -stc %s', opts.stc);
end

if ~isempty(opts.anaextra) && ~endsWith(opts.anaextra, '_')
    opts.anaextra = [opts.anaextra '_'];
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
        hemi = opts.hemis{iHemi};
        analysisName = sprintf('%s_sm%d_%s%s%s.%s', ...
            runType, opts.smooth, opts.anaextra, template, runCode, hemi);
        
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
            hemiInfo, opts.smooth, stcInfo, ... % preprocessing
            parFile, TR, ... % basic design
            nConditions, refDura, ... % event-related
            opts.nskip, thisRunFile...
            );
        fscmd{iRun, iHemi} = thisfscmd;
        
    end  % iHemi
    
end  % iRun

% save the FreeSurfer commands as one column
fscmd = fscmd(:);

% run or not running the fscmd
if opts.runcmd
    isnotok = cellfun(@system, fscmd);
else
    isnotok = zeros(size(fscmd));
end

% add isnotok to fscmd
fscmd = horzcat(fscmd, num2cell(isnotok));

% finishing message
if any(isnotok)
    warning('Some FreeSurfer commands (mkanalysis-sess) failed.');
elseif opts.runcmd
    fprintf('\nmkanalysis-sess finished without error.\n');
end

end