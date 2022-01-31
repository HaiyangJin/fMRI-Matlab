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
%                     pair. It could be either the Condition names (i.e.,
%                     the fifth column in the par file; recommended) or
%                     Condition numbers (i.e., the second column in par
%                     files).
%                 or <cell> a 1xQ (usually Q is 2) cell matrix. Each cell 
%                     is another cell str, which includes all the condition
%                     names to be grouped together. The new condition name
%                     can be set manullay via .newnames. Note that if more
%                     than one rows are provided, the results may not be
%                     correct.                     
%                    Suppose the condition names are '1', '2', '3' and '4'.
%                     {'1', '2'} will decode 1 and 2, and {{'1', '2'},
%                     {'3', '4'}} will decode the group of 1 and 2 versus
%                     the group of 3 and 4.
%
% Varargin:
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
defaultOpts = struct();
defaultOpts.writeoutput = 1;
defaultOpts.outpath = fullfile(pwd, 'Classification');
defaultOpts.outfn = 'Main_CosmoMVPA';
defaultOpts.classifier = [];
defaultOpts.classopt = [];
defaultOpts.newnames = '';
defaultOpts.target0 = [];

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
labelPairs = [];
if isnumeric(classPairs)
    classPairs = arrayfun(@num2str, classPairs, 'uni', false);
elseif iscell(classPairs) && any(cellfun(@isnumeric, classPairs), 'all')
    thenum = cellfun(@isnumeric, classPairs);
    classPairs(thenum) = cellfun(@num2str, classPairs(thenum), 'uni', false);
elseif iscell(classPairs) && iscell(classPairs(1,1))
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
        
        tempCell = cellfun(@(x, y) cosmo_cvdecode(x, classPairs, y, ...
            opts.classifier, opts.classopt),...
            ds_subj, dsInfo, 'uni', false);
        
        % run classification
        mvpaCell{iSess, iLabel} = vertcat(tempCell{:});
    end
    
end
% waitbar
waitbar(progress, waitHandle, 'Saving data...');

% combine tables together
mvpaTable = vertcat(mvpaCell{:});

%% save data to local
if ~isempty(mvpaTable)
    mvpaTable(:, 'Confusion') = [];
end

if opts.writeoutput
    fm_mkdir(opts.outpath);
    
    % MVPA for main runs
    cosmoFn = fullfile(opts.outpath, opts.outfn);
    save(cosmoFn, 'mvpaTable');
    
    writetable(mvpaTable, [cosmoFn, '.xlsx']);
    writetable(mvpaTable, [cosmoFn, '.csv']);
    
end
close(waitHandle); % close the waitbar

end