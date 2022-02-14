function overlapTable = fs_labeloverlap(labels, subjList, varargin)
% overlapTable = fs_labeloverlap(labels, subjList, varargin)
%
% This function calcualtes the overlapping between every two labels.
%
% Inputs:
%   labels            <cell str> a list (matrix) of label names (can be 
%                      more than 2). The labels in the same row will be 
%                      compared with each other. (each row is another cell).
%   subjList          <cell str> subject code in $SUBJECTS_DIR.
%
% Varargin:
%   .outpath          <str> where to save the excel output. Default is a
%                      subdirectory called within pwd. If it is
%                      'none', no output files will be saved. 
%   .outfn            <str> the filename of the output excel. Default is 
%                       'Label_Overlapping.xlsx'.
%   .surface          <str> the surface (without hemisphere information) 
%                      used to calculated area (if <.unit> is 'area').
%                      Default is 'white'. More see fs_vtxarea().
%
% %%% Overlapping coefficients %%%
%   .unit             <str> the unit to be used to calculate the
%                      overlapping coefficient. 
%   .method           <str> the method used to calculate the overlapping
%                      ratio. Options are 'dice' and 'jaccard'. More see 
%                      stat_overlap(). Default is 'none', i.e., not
%                      calculating the overlapping.
%
%
% Output
%   overlapTable      <table> a table contains the overlapping information
%
% Created by Haiyang Jin (11/12/2019)

if nargin < 1
    fprintf('Usage: overlapTable = fs_labeloverlap(labels, subjList, varargin);\n');
    return;
end

nLabelGroup = size(labels, 1);

if ischar(subjList); subjList = {subjList}; end
nSubj = numel(subjList);

defaultOpts = struct( ...
    'outpath', fullfile(pwd, 'Label_Overlapping'), ...
    'outfn', 'Label_Overlapping.xlsx', ...
    'unit', 'area', ... % 'count'
    'surface', 'white', ... % only used when unit is 'area'
    'method', 'none' ... % 'dice', 'jaccard' see stat_overlap()
    );
opts = fm_mergestruct(defaultOpts, varargin{:});

outPath = opts.outpath;
if ~strcmp(outPath, 'none') && ~exist(outPath, 'dir'); mkdir(outPath); end

n = 0;
overlapStr = struct;

for iSubj = 1:nSubj
    
    subjCode = subjList{iSubj};
%     labelPath = fullfile(FS.subjects, subjCode, 'label');
    
    for iLabel = 1:nLabelGroup
        
        theseLabels = labels{iLabel, :};
        
        nLabel = numel(theseLabels);
        if nLabel < 2
            warning('The number of labels should be more than one.');
            continue;
        end
        
        c = nchoosek(1:nLabel, 2); % combination matrix
        nC = size(c, 1); % number of combinations
        
        for iC = 1:nC
            
            theseLabel = theseLabels(c(iC, :));
            
            % skip if at least one label is not available
            if ~fs_checklabel(theseLabel, subjCode)
                continue;
            end
            
            % load the two label files
            matCell = cellfun(@(x) fs_readlabel(x, subjCode), theseLabel, 'uni', false);
            
            % check if there is overlapping between the two labels
            matLabel1 = matCell{1};
            matLabel2 = matCell{2};
            isoverlap = ismember(matLabel1, matLabel2);
            overlapVer = matLabel1(isoverlap(:, 1));
            nOverVer = numel(overlapVer);
            areaOverVer = fs_labelarea(theseLabel{1}, subjCode, overlapVer, opts.surface);

            % save information to the structure
            n = n + 1;
            overlapStr(n).SubjCode = {subjCode};
            overlapStr(n).Label = theseLabel;
            overlapStr(n).nOverlapVer = nOverVer;
            overlapStr(n).Area = areaOverVer;

            % overlappin coefficients
            if ~strcmp(opts.method, 'none')
                switch opts.unit
                    case {'count', 'c'}
                        l1 = size(matLabel1, 1);
                        l2 = size(matLabel2, 1);
                        lo = nOverVer;
                    case {'area', 'a'}
                        l1 = fs_labelarea(theseLabel{1}, subjCode, [], opts.surface);
                        l2 = fs_labelarea(theseLabel{2}, subjCode, [], opts.surface);
                        lo = areaOverVer;
                end
                
                overlapStr(n).OverlapMethod = {opts.method};
                overlapStr(n).OverlapUnit = {opts.unit};
                overlapStr(n).OverlapCoef = stat_overlap(l1, l2, lo, opts.method);
            end

            overlapStr(n).OverlapVer = {overlapVer(:)};
        end
    end
end
clear n

overlapTable = struct2table(overlapStr, 'AsArray', true); % convert structure to table
overlapTable = rmmissing(overlapTable, 1); % remove empty rows
if ~strcmp(outPath, 'none')
    writetable(overlapTable, fullfile(outPath, opts.outfn));
end

end