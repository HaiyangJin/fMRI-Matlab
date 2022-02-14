function [anaList, fscmd] = fs_mkanalysis(runFn, parfn, TR, nCond, refDura, varargin)
% [anaList, fscmd] = fs_mkanalysis(runFn, parfn, TR, nCond, refDura, varargin)
%
% This function runs mkanalysis-sess in FreeSurfer.
%
% Inputs:
%    runfn            <str> the run file which saves a list of run names.
%                      E.g., 'main.txt';
%                  OR <cell str> a cell list of run files, e.g.,
%                      {'main.txt', 'loc.txt'};
%    parfn            <str> file name of the par file (*.par)
%    TR               <num> duration of one TR (seconds).
%    nCond           <int> number of conditions (excluded fixation).
%    refDura          <num> durations of the reference condition.
%                      (the total duration of one "block" or one "trial")
%
% Varargin:
%    .template        <str> 'fsaverage' or 'self'.
%    .smooth          <num> smoothing (FWHM). Default is 0.
%    .hemis           <cell str> or <str> 'lh', 'rh' (and
%                      'mni' or 'mni1'). Default is {{'lh', 'rh'}}.
%    .stc             <str> slice-timing corretion. The argument
%                      strings for -stc. [siemens, up, down, odd, even].
%                      Default is ''.
%    .nskip           <int> number of TRs to be skipped at the run start.
%                      Default is 0.
%    .extrastr        <str> extra strings to be added to the analysis
%                      name.
%    .runcmd          <boo> whether run the fscmd in FreeSufer (i.e.,
%                      make contrasts in FreeSurfer). 1: run fscmd
%                      [default]; 0: do not run fscmds and only output
%                      conStruct and fscmd.
%
% Output:
%    anaList          <cell str> a cell of all analysis names.
%    fscmd            <cell str> FreeSurfer commands used in the current
%                      session.
%    run mkanalysis-sess in FreeSurfer.
%
% Example:
% TR = 2;  % secs
% nCond = 8;
% refDura = 16;  % secs
% % make analysis
% [anaList1, fscmd1] = fs_mkanalysis('loc.txt', 'loc.par', TR, nCond, refDura);
%
% Created by Haiyang Jin (19-Dec-2019)
%
% See also:
% [fs_preproc;] fs_mkcontrast

if nargin < 1
    fprintf('Usage: [anaList, fscmd] = fs_mkanalysis(runFn, parfn, TR, nCond, refDura, varargin)');
    return;
elseif ischar(runFn)
    runFn = {runFn};
end
nRunfn = numel(runFn);

if ~endsWith(parfn, '.par')
    parfn = [parfn '.par'];
end

defaultOpts = struct(...
    'template', 'self', ...
    'smooth', 0, ...
    'hemis', {{'lh', 'rh'}}, ...
    'stc', '', ...
    'nskip', 0, ...
    'extrastr', '', ...
    'runcmd', 1 ...
);
opts = fm_mergestruct(defaultOpts, varargin{:});

if ~ismember(opts.template, {'fsaverage', 'self'})
    warning('The template is ''%s''.', opts.template);
end

if ischar(opts.hemis)
    opts.hemis = {opts.hemis};
end
nHemi = numel(opts.hemis);

if isempty(opts.stc)
    stcInfo = '';
else
    stcInfo = sprintf(' -stc %s', opts.stc);
end

% empty cell for saving analysis names
anaList = cell(nRunfn, nHemi);

% empty cell for saving FreeSurfer commands
fscmd = cell(nRunfn, nHemi);

for iRun = 1:nRunfn
    
    thisRunFn = runFn{iRun};
    
    for iHemi = 1:nHemi
        
        % analysis name
        hemi = opts.hemis{iHemi};

        anaName = struct;
        anaName.type = 'ana';
        anaName.runs = erase(thisRunFn, '.txt');
        anaName.par = erase(parfn, '.par');
        anaName.sm = num2str(opts.smooth);
        anaName.template = opts.template;
        anaName.hemi = hemi;
        if ~isempty(opts.extrastr)
            anaName.custom = opts.extrastr;
        end
        analysisName = fp_info2fn(anaName);
        clear anaName
        
        % save the analysis names into the cell
        anaList(iRun, iHemi) = {analysisName};
        
        switch hemi
            case {'lh', 'rh'}
                hemiInfo = sprintf(' -surface %s %s', opts.template, hemi);
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
            parfn, TR, ... % basic design
            nCond, refDura, ... % event-related
            opts.nskip, thisRunFn...
            );
        fscmd{iRun, iHemi} = thisfscmd;
        
    end  % iHemi
    
end  % iRun

% run or not running the fscmd
[fscmd, isnotok] = fm_runcmd(fscmd, opts.runcmd);

% finishing message
if any(isnotok)
    warning('Some FreeSurfer commands (mkanalysis-sess) failed.');
elseif opts.runcmd
    fprintf('\nmkanalysis-sess finished without error.\n');
end

end