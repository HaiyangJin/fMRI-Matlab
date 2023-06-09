function mvpaTable = fs_cosmo_cvdecode(sessList, anaList, labelList, ...
    classPairs, varargin)
% mvpaTable = fs_cosmo_cvdecode(sessList, anaList, labelList, ...
%   classPairs, varargin)
%
% Performs the cross-validation classification (decoding) for all
% sessions and all classification pairs.
%
% Inputs:
%    sessList        <cell str> a list of session codes.
%    anaList         <cell str> a list of analysis names. This should be
%                     two analyses, which are essentially the same analysis
%                     but for different hemispheres.
%    labelList       <cell str> a list of label names.
%    classPairs      <cell str> a PxQ (usually Q is 2) cell matrix for the
%                     pairs to be classified. Each row is one classfication
%                     pair. It should be the Condition names (e.g.,
%                     the fifth column in the par file).
%                 or <cell of cell str> a 1xQ (usually Q is 2) cell matrix. 
%                     Each cell is another cell str, which includes all the
%                     condition names to be grouped together. The new 
%                     condition name can be set manullay via .newnames.
%                     Note that if more than one rows are provided, the 
%                     results may not be correct. 
%                    Example: Suppose the condition names are 'a', 'b', 
%                     'c' and 'd'. 
%                     {'a', 'b'} will decode 'a' and 'b';
%                     {{'a', 'b'}, {'c', 'd'}} will decode the group of 1 
%                     and 2 versus the group of 3 and 4.
%
% Varargin:
%    .method         <str> decode method: 'classify' (default; 
%                     cross-validation decoding), 'corr-targets'
%                     (correlations
%                     
%    .writeoutput    <boo> whether write the output into .csv and .xlsx
%                     files. Default is 1. When it is 0, outpath and outfn
%                     will be ignored.
%    .outpath        <str> where to save the output file. The output will
%                     be saved in a folder named 'Classification' within the
%                     current wording directory by default.
%    .outfn          <str> the filename of the output file.
%    .classifier     <num> or <str> or <cells> the classifiers to be used
%                     (only 1). Default is 'libsvm'.
%    .classopt       <struct> the possibly other fields that are given to
%                     the classifer. Default is empty struct. E.g., 'c' and
%                     'autoscale' for libsvm.
%    .cortypes       <cell str> correlation types to be used. Default is ''.
%    .coropt         <str> more see options in cosmo_correlation_measure().
%    .newnames       <cell str> a 1xQ cell matrix (the size is the same as
%                     [classPairs]).
%    .target0        <int> initial target code (number) for the new labels.
%                     Default is maximum target number in ds_in.
%
%  <all other options in fs_cosmo_sessds>. E.g.,:
%    .datafn         <str> the data file to be used for decoding.
%                     ['' by default and it will use 'beta.nii.gz'].
%
% Outputs:
%    mvpaTable       <table> MVPA result table.
%                     And save mvpaTable locally.
%
% The column names in mvpaTable:
%    'Label'            the FreeSurfer label for this classification.
%    'Analysis'         the FS-FAST analysis for this classifciation.
%    'nVertices'        the number of vertices in the label.
%    'SessCode'         the session code.
%    'ClassifyPair'     the decoding pair. The two conditions are separated
%                         by '-'.
%    'Classifier'       the employed classifier.
%    'Run'              the test run.
%    'Predicted'        the predicted result from the trained classifier.
%    'Target'           the real condition code, i.e., the answer.
%    'TargetName'       the real condition name.
%    'ACC'              whether the prediction is correct.
%
% Created by Haiyang Jin (12-Dec-2019)

%% Deal with inputs
% waitbar
waitHandle = waitbar(0, 'Loading...   0.00% finished');

if ischar(sessList); sessList = {sessList}; end
nSess = numel(sessList);
if ischar(anaList); anaList = {anaList}; end
if ischar(labelList); labelList = {labelList}; end
nLabel = numel(labelList);

% default settings
defaultOpts = struct( ...
    'method', 'classify', ...
    'writeoutput', 1, ...
    'outpath', fullfile(pwd, 'Classification'), ...
    'outfn', 'Main_CosmoMVPA', ...
    'classifier', [], ...
    'classopt', [], ...
    'coropt', [], ...
    'cortypes', [], ...
    'newnames', [], ...
    'target0', [] ...
    );

opts = fm_mergestruct(defaultOpts, varargin(:));

% opts for fs_cosmo_sessds
dsopts = opts;
dsopts.runwise = 1;
dsopts.writeouput = [];
dsopts.outpath = [];
dsopts.outfn = [];
dsopts.classifier = [];
dsopts.classopt = [];

% convert classPairs to char if needed
assert(iscell(classPairs), 'classPairs has to be a cell.')
labelPairs = [];
if iscell(classPairs) && iscell(classPairs{1,1})
    % multiple conditions vs. multiple conditions
    if isempty(opts.newnames)
        newnames = cellfun(@(x) sprintf('%s&', x{:}), classPairs, 'uni', false);
        opts.newnames = cellfun(@(x) x(1:end-1), newnames, 'uni', false);
    end
    labelPairs = horzcat(opts.newnames(:), classPairs(:));
end

%% Cross validation decode
% create empty table
mvpaCell = cell(nSess, nLabel);

for iSess = 1:nSess

    % this subject code (bold)
    thisSess = sessList{iSess};

    for iLabel = 1:nLabel

        % this label
        thisLabel = labelList{iLabel};

        % waitbar
        progress = ((iSess-1)*nLabel + iLabel) / (nLabel * nSess);
        progressMsg = sprintf('Label: %s.  Subject: %s \n%0.2f%% finished...', ...
            thisLabel, strrep(thisSess, '_', '\_'), progress*100);
        waitbar(progress, waitHandle, progressMsg);

        % get the corresponding analysis name
        isAna = contains(anaList, fm_2hemi(thisLabel));
        theAna = anaList(isAna);

        % get data for CoSMoMVPA
        dsopts.labelfn = thisLabel;
        [ds_subj, dsInfo] = cellfun(@(x) fs_cosmo_sessds(thisSess, x, dsopts), ...
            theAna, 'uni', false);

        if ~isempty(labelPairs)
            ds_subj = cellfun(@(x) cosmo_labelds(x, labelPairs, opts.target0), ...
                ds_subj, 'uni', false);
            classPairs = opts.newnames;
        end

        switch opts.method

            % corss-validation decoding
            case 'classify'
                tmpCell = cellfun(@(x, y) cosmo_cvdecode(x, classPairs, y, ...
                    opts.classifier, opts.classopt),...
                    ds_subj, dsInfo, 'uni', false);

            % correlations between conditions (across runs/chunks)
            case {'corr-targets', 'corr-t'}
                tmpCell = cellfun(@(x, y) cosmo_corr_conditions(x, y, ...
                    opts.cortypes, {'targets'}), ...
                    ds_subj, dsInfo, 'uni', false);

            % correlations between conditions and runs
            case {'corr-targetschunks', 'corr-tc'}
                tmpCell = cellfun(@(x, y) cosmo_corr_conditions(x, y, ...
                    opts.cortypes), ...
                    ds_subj, dsInfo, 'uni', false);

            % split half corrlations
            case {'corr-oddeven', 'oddeven'} % split-half
                tmpCell = cellfun(@(x, y) cosmo_corr_oddeven(x, y, ...
                    opts.cortypes, opts), ...
                    ds_subj, dsInfo, 'uni', false);

            otherwise
                error('Unknown methods.')

        end

        % run classification
        mvpaCell{iSess, iLabel} = vertcat(tmpCell{:});
    end

end
% waitbar
waitbar(progress, waitHandle, 'Saving data...');

% combine tables together
mvpaTable = vertcat(mvpaCell{:});

%% save data to local
if ~isempty(mvpaTable) && strcmp(opts.method, 'classify')
    mvpaTable(:, 'Confusion') = [];
end

if opts.writeoutput
    fm_mkdir(opts.outpath);

    % MVPA for main runs
    cosmoFn = fullfile(opts.outpath, opts.outfn);
    save(cosmoFn, 'mvpaTable');

    if strcmp(opts.method, 'classify')
        writetable(mvpaTable, [cosmoFn, '.xlsx']);
        writetable(mvpaTable, [cosmoFn, '.csv']);
    end

end
close(waitHandle); % close the waitbar

end