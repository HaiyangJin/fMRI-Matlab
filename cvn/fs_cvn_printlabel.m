function infoTable = fs_cvn_printlabel(labelList, sessList, thmins, outPath, extraopt1st)
% infoTable = fs_cvn_printlabel(labelList, sessList, thmins, outPath, extraopt1st)
%
% This function prints the label files only (without the overlay
% activations for the whole brain).
%
% Inputs:
%    labelList       <cell string> list of label names or list of contrast
%                     names.
%    sessList        <cell string> list of session codes (in funcPath). The
%                     number of sessList has to be the same as that of
%                     'labelList'.
%    thmins          <numeric array> a vector of minimum thresholds.
%                     Default is from the minimum to the maximum values in
%                     the label by the step of 0.1.
%    outPath         <string> where to save the output images. [current
%                     folder by default].
%    extraopt1st     <cell> extra varargin used in fs_cvn_print1st.m.
%
% Output:
%    infoTable       <table> the information table of labels when different
%                     minimum thresholds are used.
%
% Created by Haiyang Jin (11-May-2020)

if ~exist('thmins', 'var') || isempty(thmins)
    thmins = [];
end
if ~exist('outPath', 'var') || isempty(outPath)
    outPath = fullfile(pwd, 'print_label');
end
if ~exist('extraopt1st', 'var') || isempty(extraopt1st)
    extraopt1st = {};
end

if ischar(labelList); labelList = {labelList}; end
if ischar(sessList); sessList = {sessList}; end

nLabel = numel(labelList);

assert(nLabel == numel(sessList), ['The number of labels has to be the '...
    'same as that of subjects. (Or you may use fs_cvn_print1st.m instead']);

% gather information for each label/subject
infoCell = cell(nLabel, 1);
for iLabel = 1:nLabel
    
    % this label/session/subject
    thisLabel = labelList{iLabel};
    thisSess = sessList{iLabel};
    thisSubj = fs_subjcode(thisSess);
    
    % set the minimum thresholds
    if isempty(thmins)
        labelMat = fs_readlabel(thisLabel, thisSubj);
        [themin, themax] = bounds(labelMat(:, 5)*10);
        thmins0 = (floor(themin):1:floor(themax))/10;
    else
        thmins0 = thmins;
    end
    
    fprintf('Printing the results for the label... [%d/%d]<%d>\n', ...
        iLabel, nLabel, numel(thmins0));
    
    % create the figure
    arrayfun(@(x) fs_cvn_print1st(thisSess, '', thisLabel, outPath, ...
        'waitbar', 0, 'suffixstr', sprintf('f%1.f', x*10), 'thresh', x, extraopt1st{:}),...
        thmins0, 'uni', false);
    
    % gather the information
    tempCell = arrayfun(@(x) fs_labelinfo(thisLabel, thisSubj, ...
        'isndgrid', 0, 'bycluster', 1, 'fmin', x), thmins0', 'uni', false);
    infoCell{iLabel, 1} = vertcat(tempCell{:});
    
end

% save the information as a table
infoTable = vertcat(infoCell{:});

end