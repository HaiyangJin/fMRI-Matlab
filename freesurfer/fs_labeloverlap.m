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
% %%% Overlapping ratio %%%
%   .olmethod         <str> the method used to calculate the overlapping
%                      ratio. Options are 'dice' and 'jaccard'. More see
%                      stat_overlap(). Default is '', i.e., not calculating
%                      the overlapping ratio.
%   .olunit           <str> the unit to be used to calculate the
%                      overlapping coefficient; 'count' (the number of 
%                      vertices) or 'area' (the area of vertices; default).
%
% %%% location distance %%%
%   .distmetric       <str> the distance metric. Options are 'euclidean',
%                      'geodesic' and 'dijkstra'. Default is '', i.e., not
%                      calculating the distance.
%   .location         <str> 'peak' or 'center' (not in use yet).
%
% Output
%   overlapTable      <table> a table contains the overlapping information
%
% Explanation of columns in the output overlap table (not all the columns
% will be avaiable in the output table):
%   SubjCode          subject code in $SUBJECTS_DIR.
%   Label             a pair of labels.
%   nOverlapVtx       number of the vertices in the overlapping part.
%   Area              area size of the overlapping part.
%   OverlapMethod     the method used to calculate the overlapping ratio.
%   OverlapUnit       the unit used to calculate the overlapping ratio.
%   OverlapRatio      the calculated overlapping Ratio.
%   location          which is used to represent the location of the label.
%   distmetric        the metric used to calculate the distance.
%   distance          the calculate distance.
%   OverlapVtx        the indices of all the overlapping vertices.
%
% % Example 1: overlap begtween two labels
% olT = fs_labeloverlap({{label1, label2}}, subjCode);
%
% % Example 2: overlap among multiple labels
% olT = fs_labeloverlap({{label1, label2}; {label3, label4}}, subjCode);
% 
% % Example 3: calculate the dice coefficient (overlapping ratio)
% olT = fs_labeloverlap({{label1, label2}}, subjCode, 'olmethod', 'dice');
%
% % Example 4: calculate the geodesic distance between peaks
% olT = fs_labeloverlap({{label1, label2}}, subjCode, 'distmetric', 'geodesic');
%
% Created by Haiyang Jin (2019-12-11)

if nargin < 2
    fprintf('Usage: overlapTable = fs_labeloverlap(labels, subjList, varargin);\n');
    return;
end

if size(labels, 2) > 1
    labels = {labels};
end
nLabelGroup = size(labels, 1);

if ischar(subjList); subjList = {subjList}; end
nSubj = numel(subjList);

defaultOpts = struct( ...
    'outpath', fullfile(pwd, 'Label_Overlapping'), ...
    'outfn', 'Label_Overlapping.xlsx', ...
    'surface', 'white', ... % only used when unit is 'area'
    'olmethod', '', ... % 'dice', 'jaccard' see stat_overlap()
    'olunit', 'area', ... % 'count'
    'distmetric', '', ...
    'location', 'peak' ...
    );
opts = fm_mergestruct(defaultOpts, varargin{:});

outPath = opts.outpath;
if ~strcmp(outPath, 'none') && ~exist(outPath, 'dir'); mkdir(outPath); end

%% Gather overlapping information
overlapC = cell(nSubj, nLabelGroup);

for iSubj = 1:nSubj

    subjCode = subjList{iSubj};

    for iLabel = 1:nLabelGroup

        theseLabels = labels{iLabel, :};

        % make sure the labels are for the same hemisphere
        [~, nHemi] = fm_hemi_multi(theseLabels);
        assert(nHemi==1, 'Labels in the same group should be from the same hemisphere.')

        nLabel = numel(theseLabels);
        if nLabel < 2
            warning('The number of labels should be more than one.');
            continue;
        end

        c = nchoosek(1:nLabel, 2); % combination matrix
        nC = size(c, 1); % number of combinations
        overlapSC = cell(nC, 1); % to save the output

        for iC = 1:nC

            labelPair = theseLabels(c(iC, :));

            % skip if at least one label is not available
            if ~fs_checklabel(labelPair, subjCode)
                continue;
            end
            % gather the overlapping information for each pair
            overlapSC{iC,1} = labeloverlap(labelPair, subjCode, opts);

        end

        overlapC{iSubj, iLabel} = vertcat(overlapSC{:});
    end
end

overlapStr = vertcat(overlapC{:});
overlapTable = struct2table(overlapStr, 'AsArray', true); % convert structure to table
overlapTable = rmmissing(overlapTable, 1); % remove empty rows
if ~strcmp(outPath, 'none')
    writetable(overlapTable, fullfile(outPath, opts.outfn));
end

end

function overlapS = labeloverlap(labelPair, subjCode, opts)
% labelPair: a pair of labels to be contrasted
% subjCode: subject code in $SUBJECTS_DIR

% avaiable options for overlapping and distance
olopts = {'dice'; 'jaccard'};
ldopts = {'euclidean', 'geodesic', 'dijkstra'};

if ischar(opts.surface)
    [coords, faces] = fs_readsurf([fm_hemi_multi(labelPair), '.' opts.surface], subjCode);
else
    coords = opts.surface{1};
    faces = opts.surface{2};
end

% load the two label files
matCell = cellfun(@(x) fs_readlabel(x, subjCode), labelPair, 'uni', false);

% check if there is overlapping between the two labels
matLabel1 = matCell{1};
matLabel2 = matCell{2};
isoverlap = ismember(matLabel1, matLabel2);
overlapVtx = matLabel1(isoverlap(:, 1));
nOverVtx = numel(overlapVtx);
if isempty(overlapVtx)
    areaOverVtx = 0; 
else
    areaOverVtx = fs_labelarea(labelPair{1}, subjCode, overlapVtx, {coords, faces});
end

% save information to the structure
overlapS = struct;
overlapS.SubjCode = {subjCode};
overlapS.Label = labelPair;
overlapS.nOverlapVtx = nOverVtx;
overlapS.Area = areaOverVtx;

%% overlapping ratio
if ismember(opts.olmethod, olopts)
    switch opts.olunit
        case {'count', 'c'}
            l1 = size(matLabel1, 1);
            l2 = size(matLabel2, 1);
            lo = nOverVtx;
        case {'area', 'a'}
            l1 = fs_labelarea(labelPair{1}, subjCode, [], {coords, faces});
            l2 = fs_labelarea(labelPair{2}, subjCode, [], {coords, faces});
            lo = areaOverVtx;
    end

    overlapS.OverlapMethod = {opts.olmethod};
    overlapS.OverlapUnit = {opts.olunit};
    overlapS.OverlapRatio = stat_overlap(l1, l2, lo, opts.olmethod);
end

%% location distance
if ismember(opts.distmetric, ldopts)

    % identify the location
    switch opts.location
        case 'peak'
            value1 = abs(matLabel1(:,5));
            value2 = abs(matLabel2(:,5));

            assert(all(value1 > 0), 'Cannot determine the peak for %s.', labelPair{1});
            assert(all(value2 > 0), 'Cannot determine the peak for %s.', labelPair{2});

            [~, i1] = max(value1);
            [~, i2] = max(value2);

            peakvtx1 = matLabel1(i1, 1);
            peakvtx2 = matLabel2(i2, 1);

        case 'center'
            warning('This method of ''center'' location is still under development.')
            vtxinfo1 = fs_labelcenter(labelPair{1}, subjCode, ...
                'surface', {coords, faces}, 'distmetric', opts.distmetric);
            vtxinfo2 = fs_labelcenter(labelPair{2}, subjCode, ...
                'surface', {coords, faces}, 'distmetric', opts.distmetric);

            peakvtx1 = vtxinfo1(1);
            peakvtx2 = vtxinfo2(1);
    end

    % calculate the distance
    switch opts.distmetric
        case ldopts(1) % Euclidean
            D = pdist(coords([peakvtx1, peakvtx2], :));

        case ldopts(2) % geodesic
            % this requires the Fast Marching toolbox (Peyre)
            Ds = perform_fast_marching_mesh(coords, faces, peakvtx1);
            % only keep distances between vertices in the label
            D = Ds(peakvtx2);

        case ldopts(3) % dijkstra
            Ds = surfing_dijkstradist(coords', faces', peakvtx1);
            % only keep distances between vertices in the label
            D = Ds(peakvtx2);
    end

    overlapS.location = opts.location;
    overlapS.distmetric = opts.distmetric;
    overlapS.distance = D;

end
overlapS.OverlapVtx = {overlapVtx(:)};

end