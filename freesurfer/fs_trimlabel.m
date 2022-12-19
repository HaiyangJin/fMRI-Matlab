function [labelMatCell, cluVtxCell] = fs_trimlabel(labelFn, sessCode, outPath, varargin)
% [labelMatCell, cluVtxCell] = fs_trimlabel(labelFn, sessCode, outPath, varargin)
%
% This function updates the label file for different purposes (see below).
% By default, the last column in the label file will be used to sort the
% vertices. But you may use 'overlay' to custom the values for sorting
% vertices (note: the 'overlay' has to be for the whole surface).
%
% Please note it seems that the label created by FreeSurfer 7.2 (FreeView)
% and potentially later versions, the functional data used to identify ROI
% were not saved in the last column of the label file. In this case, only
% the 'concentric' method works. If you would like to use 'maxresp', you
% need to adopt one of the two approaches:
%    (1) use 'analysis' and 'valuefn' to set the analysis and file used to
%        trim the label.
%    (2) use 'overlay' to set the functional data to be used to trim the
%        label (e.g., p-values used to identify the ROI) [you may use
%        fm_readimg() to read the functional data into Matlab].
%
% Inputs:
%    labelFn       <str> the label file name saved in label/.
%    sessCode      <str> session code in $FUNCTIONALS_DIR if '.overlay'
%                   is empty.
%               OR <str> subject code in $SUBJECTS_DIR if '.overlay' is not
%                   empty.
%    outPath       <str> path to the folder for saving some temporary
%                   images.
%
% Options (varargin):
%    'method'      <str> different methods for dilating the global
%                   maxima to a cluster/roi. The options are 'concentric',
%                   'maxresp'[default], or 'con-maxresp'. More see below.
%    'surfdef'     <cell> {vertices, faces}.
%               OR <str> the surface string, e.g., 'white', 'pial'. The
%                   hemisphere information will be read from labelFn.
%    'analysis'    <str> the analysis used to create the label. If
%                   'overlay' is not empty, 'analysis' will be ignored.
%    'valuefn'     <str> the file (in the contrast folder) used to create
%                   the label. Default is 'sig.nii.gz'. If 'overlay' is not
%                   empty, 'valuefn' will be ignored.
%    'overlay'     <num vec> result (e.g., FreeSurfer p-values) to be
%                   displayed on the surface. It has to be the result for
%                   the whole 'surfdef'. Default is ''.
%    'sortorder'   <str> the order of sorting the vertices by the absolute
%                   values of overlay: 'ascend' or 'descend' [default].
%                   (Probalby this should be deprecated.)
%    'ncluster'    <int> cluster numbers. Default is 1.
%    'startvtx'    <int> index of the starting vertex. This should be
%                   the vertex index in the Matlab (i.e., already + 1).
%                   Default is []. If 'startvtx' is used, ncluster will be
%                   set as 1 and 'lowerthresh' will be set as true. [Not
%                   fully developed. Ths startvtx might not be the global
%                   maxima.] Note: when 'startvtx' is not empty and
%                   'savegm' is 1, startvtx will be saved as 'gmfn'.
%    'gmfn'        <str> the filename of the local maxima to be used.
%                   Default is '' (empty) and no local maxima saved before
%                   will be used. if 'gmfn' is not empty and the file
%                   exists, the vertex index in the file will be used as
%                   the local maxima and 'startvtx' will be ignored.
%    'savegm'      <boo> 1 [default]: save the local maxima (matlab
%                   vertex index) used for creating the updated label as a
%                   file. Its filename will be the same as the label
%                   filename (replace '.label' as '.gm'. 0: do not save the
%                   local maxima.
%    'gminfo'      <boo> 0: do not show global maxima information;
%                   1 [default]: only show the global maxima information,
%                   but not the maxresp; 2: show both global maxima and 
%                   maxresp information.
%    'maxsize'     <num> the maximum cluster size (mm2) [based on
%                   ?h.white]. Default is 100.
%    'minsize'     <num> the minimum cluster size (mm2) [based on
%                   ?h.white]. Default is 20 (arbitrary number).
%    'lagnvtx'     <int> number (lagvtx-1) of vertex values to be
%                   skipped for checking cluster numbers with certain
%                   threshold (value). Default is 100. e.g., if there are
%                   200 vertices in the label, The value of vertices
%                   (1:100:200) will be used as cluster-forming thresholds.
%    'lagvalue'    <num> lag of values to be skipped for checking
%                   cluster numbers. Default is []. e.g., if the values in
%                   the label range from 1.3 to 8. The values of 1.3:.1:8
%                   will be used as clustering-forming threshold.
%                   'lagvalue' will be used if it is not empty.
%    'maxiter'     <num> the maximum number of iterations for
%                   checking clusters with different clusterwise
%                   "threshold". Default is 20. If the interation (i.e.,
%                   nIter) is larger than 'maxiter' after applying
%                   'lagnvtx' and 'lagvalue' , 'maxiter' of 'fmins' will be
%                   selected randomly. [If the value is too large, it will
%                   take too long to identify the clusters.]
%    'keepratio'   <num> how much of data will be kept when 'maxresp'
%                   method is used. Default is 0.5.
%    'lowerthresh' <boo> 1 [default]: release the restriction of the
%                   KEY threshold, and all vertices in the label can be
%                   assigned to one cluster. 0: only the vertices whose
%                   values are larger than the KEY threshold can be assigned
%                   to one cluster. [KEY threshold] can be taken as the
%                   largest p-value that forms nCluster clusters.
%    'reflabel'    <cell str> reference (existing) labels. Default is
%                   '', i.e., no reference lables. Hemisphere information
%                   in the reflabel will be udpated to match labelFn is
%                   necessary.
%    'warnoverlap' <boo> 1 [default]: dispaly if there are overlapping
%                   between clusters; 0: do not dispaly.
%    'smalleronly' <boo> 0 [default]: include vertices ignoring the
%                   values. [Maybe not that useful]. 1: only include
%                   vertices whose values are smaller than that of the
%                   staring vertex in the cluster;
%    'savesize'    <boo> 0 [default]: do not save the area size
%                   information in the label file name; 1: save the area
%                   size information at the end; 2: save the area size 
%                   information after 'roi.'.
%    'peakonly'    <boo> 1 [default]: only show the peak when identify
%                   local maxima; 0: show the outline of the label.
%    'showinfo'    <boo> 0 [default]: show more information; 1: do not
%                   show label information.
%    'extraopt1st' <cell> options used in fs_cvn_print1st.m.
%
% Outputs:
%    labelMatCell  <cell> label matrix for each cluster.
%    cluVtxCell    <cell> vertex indices for each cluster.
%
% Different usage:
% 1: Reduce one label file to a fixed size (e.g., 100mm^2) on ?h.white.
%    Step 1: Use the vertex whose value is the strongest or custom vertex
%       ('startvtx') as staring point;
%    Step 2: Dilate until the label area reaches a fixed size ('maxsize').
%    Step 3: Save and rename the updated lable files.
%    e.g.:
%       fs_trimlabel(labelFn, sessCode, outPath);
%
% 2: Separate one label file into several clusters ('ncluster'):
%    Step 1: Idenitfy the largest p-value (i.e., FreeSurfer p-values) that
%        can separate the label into N clusters.
%    Step 2: Identify the local maxima for each cluster and they will be
%        used as the starting point.
%    Step 3: Dilate until the label area reaches a fixed size ('maxsize').
%    Step 4: Rename and save the updated lable files.
%    Step 5: Warning if there is overlapping between labels. [The
%        overlapping can be removed with fs_setdifflabel.m later.]
%    Step 6: Save and rename the updated label files.
%
% Methods for 'dilating the local maxima':
% 1. 'concentric'
%    Step 1: Identify the neighbor vertices of the local maxima and
%        calculate the area of all these vertices.
%    Step 2: Identify the outside neighbor vertices of all the vertices
%        in Step 1, and calcuate the total area.
%    Step 3: Keep including more neighbor vertices until the total area
%        exceeds 'maxsize'. Then for the most outside neighbor vertices,
%        only the ones whose responses are the most active will be kept.
%        [Also trying to make the total area close to 'maxsize'.]
%    Note: this method may not capture the most active vertices as it
%        select vertices concentrically.
%
% 2. 'maxresp' [default]
%    Step 1: Identify the neighbor vertices of the local maxima and
%        only keep the first 'keepratio' (e.g., 50%) of the most active
%        neighbor vertices.
%    Step 2: Identify the neighbor vertices of the vertices in Step 1 and,
%        again, only keep the first 'keepratio' (e.g., 50%) of the most
%        active neighbor vertices.
%    Step 3: Keep including more neighbor vertices until the total area
%        is close enough to but not exceed 'maxsize'.
%    Note: The local maxima is not necessarily in the center.
%    Special note: when 'keepratio' is 100%, the final label will be quite
%        similar to (or the same as) that generated by 'concentric' for the
%        same local maxima.
%
% 3. 'con-maxresp'
%    [not fully developed.]
%    Step 1: Use 'concentric' method to generate the cluster/roi for the
%        local maxima.
%    Step 2: Within this cluster, select the most active vertices as the
%        final label.
%    Note: the vertices in the final label are not necessarily contiguous.
%
% Created by Haiyang Jin (14-May-2020)

fprintf('\nUpdating %s for %s...\n', labelFn, sessCode);

%% Deal with inputs
defaultOpts = struct(...
    'method', 'maxresp', ...
    'surfdef', 'white', ...
    'analysis', '', ...
    'valuefn', 'sig.nii.gz', ...
    'overlay', '', ...
    'sortorder', 'descend', ...
    'ncluster', 1, ...
    'startvtx', [], ...
    'gmfn', '', ...
    'savegm', 1, ...
    'gminfo', 0, ...
    'maxsize', 100, ...
    'minsize', 10, ...
    'lagnvtx', 100, ...
    'lagvalue', [], ...
    'maxiter', 20, ...
    'keepratio', 0.5, ...
    'lowerthresh', 1, ...
    'reflabel', '', ...
    'warnoverlap', 1, ...
    'smalleronly', 0, ...
    'savesize', 0, ...
    'peakonly', 0, ...
    'showinfo', 0, ...
    'showgm', 0, ...
    'extraopt1st', {{}} ...
    );

opts = fm_mergestruct(defaultOpts, varargin);

nCluster = opts.ncluster;
startVtx = opts.startvtx;
maxSize = opts.maxsize;
lowerThresh = opts.lowerthresh;
refLabel = opts.reflabel;
extraOpt = opts.extraopt1st;

% convert sessCode to subjCode
% if isempty(opts.overlay)
subjCode = fs_subjcode(sessCode);
% else
%     subjCode = sessCode;
% end

if ~exist('outPath', 'var') || isempty(outPath)
    outPath = fullfile(pwd, 'temporary');
end
if ~exist(outPath, 'dir'); mkdir(outPath); end

if opts.showinfo
    extraOpt = [{'annot', 'aparc', 'showinfo', 0, 'showpeak', 1}, extraOpt];
end

% use the local maxima saved before as 'startVtx' if needed
if ~isempty(opts.gmfn)
    gmFile = fullfile(getenv('SUBJECTS_DIR'), subjCode, 'label', opts.gmfn);
    if ~exist(gmFile, 'file')
        warning('Cannot find the gm file...');
        labelMatCell = cell(1,1);
        cluVtxCell = cell(1,1);
        return;
    end
    startVtx = str2double(fm_readtext(gmFile));
end

% convert refLabel to cell and match hemisphere information
if ischar(refLabel); refLabel = {refLabel}; end
theHemi = fm_2hemi(labelFn);
oldHemi = setdiff({'lh', 'rh'}, theHemi);
refLabel = cellfun(@(x) strrep(x, oldHemi{1}, theHemi), refLabel, 'uni', false);

% only show local maxima for selecting roi (analysis for fs_cvn_print1st())
anaInfo = sprintf('labeloverlay.%s', theHemi);
if ~isempty(opts.overlay)
    anaInfo = sprintf('custom.%s', theHemi);
    opts.analysis = '';
end

if ~isempty(opts.analysis)
    % read the functional data if 'analysis' is not empty
    anaInfo = opts.analysis;
    opts.overlay = fm_readimg(fullfile(getenv('FUNCTIONALS_DIR'), sessCode, ...
        'bold', opts.analysis, fm_2contrast(labelFn), opts.valuefn));
end

if opts.peakonly
    extraOpt = [{'peakonly', 1}, extraOpt];
    anaInfo = sprintf('nooverlay.%s', theHemi);
end

% sort orders
orders = {'ascend', 'descend'};
orderok = ismember(orders, opts.sortorder);
assert(any(orderok), [".sortorder has to be" ...
    " either 'ascend' or 'descend' (but not %s)."], opts.sortorder);
% order to sort the key thresholds (opposite to opts.sortorder)
threshorder = orders{~orderok};


%% Check if the label is available
labelMat = fs_readlabel(labelFn, subjCode);

% return if the label is not available.
if isempty(labelMat)
    labelMatCell = {};
    cluVtxCell = {};
    warning('Cannot find the label or the label is empty.');
    return;
end

% surface definition
if ischar(opts.surfdef)
    [vertices, faces] = fs_readsurf(sprintf('%s.%s', theHemi, opts.surfdef), subjCode);
elseif iscell(opts.surfdef)
    [vertices, faces] = opts.surfdef{:};
end

% add opts.overlay to labelMat if it is not empty
if ~isempty(opts.overlay)
    % make sure overlay match the surface definition
    assert(numel(opts.overlay)==size(vertices,1), '.overlay does not seem to match .surfdef...');

    % use the overlay results to update the label
    labelMat(:, end) = opts.overlay(labelMat(:,1));
end

% throw warning if no functional data are available in the label file
if ~any(labelMat(:, 5)) && strcmp(opts.method, 'maxresp')
    opts.method = 'concentric';
    warning('%s \n%s', ['The functional data used to create the label ' ...
        'is not avaiable in the label file.'], ...
        '''concentric'' method will be used.');
end

% add area information (the sixth column)
vtxarea=surfing_surfacearea(vertices,faces);
labelMatArea = horzcat(labelMat, vtxarea(labelMat(:,1)));

% sanity check: there should be only 1 cluster
[~, theNClu] = sf_clusterlabel(labelMatArea, faces);
assert(theNClu==1, 'There are more than one cluster in the label.');

% areas for this label
if sum(labelMatArea(:,end)) < maxSize && nCluster == 1
    % skip checking clusters
    warning('The label area (%s) is smaller than the ''maxSize'' (%s).', ...
        labelFn, subjCode);
    cluVtxCell = {labelMatArea(:, 1)};

    % find the local maxima
    [~, theMax] = max(abs(labelMatArea(:, end-1)));
    gmCell = {labelMatArea(theMax, 1)};

else
    %% Identify the clusters
    % obtain the neighbor vertices
    nbrVtx = sf_neighborvtx(labelMatArea(:, 1), faces);

    if ~isempty(startVtx)
        % use startVtx if it is not empty
        nCluster = 1;
        lowerThresh = 1;

        keyCluNoC{1,1} = ones(size(labelMatArea, 1), 1);
        keyIterC = keyCluNoC;

    else
        % identify all unqiue vertex values
        vtxValues = sort(abs(unique(labelMatArea(:, end-1))), threshorder);

        % obtain the minimum values to be used as cluster-forming thresholds
        if ~isempty(opts.lagvalue)
            % use lag values
            [labelMin, labelMax] = bounds(vtxValues);
            fmins = (labelMin:opts.lagvalue:labelMax)';
        else
            % use lag vertex number
            fmins = vtxValues(1:opts.lagnvtx:numel(vtxValues));
        end

        % apply the maximum iteration for checking clusters
        nIter = numel(fmins);
        if nIter > opts.maxiter
            fmins = fmins(sort(randperm(nIter, opts.maxiter), threshorder));
            fprintf('Following thresholds are randomly selected from ''fmin'':\n');
            disp(fmins);
        end

        % identify the clusters with all thresholds
        fprintf('Identifying the clusters... [%d/%d]\n', numel(fmins), nIter);
        [cluNoC, nCluC, iterC] = arrayfun(@(x) sf_clusterlabel(labelMatArea, faces, x), fmins, 'uni', false); %
        nClu = cell2mat(nCluC);

        % update nCluster to the maximum of clusters
        if max(nClu) < nCluster
            nCluster = max(nClu);
            warning('Only %d clusters are found in this label.', nCluster);
        end

        % find the KEY indices, for which the cluster number matches nCluster
        % and the previous cluster number doe not match nCluster. There can be
        % multiple KEY indices if nCluster > 1. When nCluster is 1, only the
        % largest p-value (smallest FreeSurfer p-values) that that identifying
        % one cluster will be used.
        isKeyTh = 0;
        while ~any(isKeyTh) && nCluster < 11
            % keep matching the nCluster
            isKeyTh = nClu == nCluster & [true; nClu(1:end-1) ~= nCluster];
            if ~any(isKeyTh)
                warning(['Cannot find %d cluster(s) and will use %d ' ...
                    'clusters now...'], nCluster, nCluster + 1);
                % add one if needed
                nCluster = nCluster + 1;
            end
        end

        % only keep the first key if nCluster is 1
        if nCluster == 1
            firstKey = find(isKeyTh, 1);
            isKeyTh = false(size(isKeyTh));
            isKeyTh(firstKey) = true;
        end
        fprintf('There are %d KEY threshold(s) generating %d clusters...\n', ...
            sum(isKeyTh), nCluster);

        % save the corresponding ClusterNo and iterations
        keyCluNoC = cluNoC(isKeyTh, :);
        keyIterC = iterC(isKeyTh, :);

    end

    %% Try to identify vertices for the label
    % create empty cell for saving the vertex numbers
    nKeyCluNoC = numel(keyCluNoC);
    cluVtxCell = cell(nCluster, nKeyCluNoC);
    % create empty array (-1) for saving the local maxima
    gmCell = cell(nCluster, nKeyCluNoC);

    for ith = 1:nKeyCluNoC

        % this key ClusterIdx and iter
        thisCluNo = keyCluNoC{ith, 1};
        thisIter = keyIterC{ith, 1};

        % Identify each cluster separately
        for iClu = 1:nCluster

            % find vertices (and related information) for this cluster
            isThisClu = thisCluNo == iClu;
            theLabelMat = labelMatArea(isThisClu, :);
            thisCluIter = thisIter(isThisClu);
            theNbrVtx = nbrVtx;

            % find the index and vertex number for strongest response [the
            % local maxima].
            % (i.e., the first iteration)
            [~, theMax] = min(thisCluIter);
            theVtx = theLabelMat(theMax, 1);

            % assign the startVtx manually if it is available
            if ~isempty(startVtx)
                theVtx = startVtx;
            end

            % relese the restriction of KEY threshold
            if lowerThresh
                if opts.smalleronly
                    % only values smaller than the starting vertex can be
                    % included in this cluster
                    isSmaller = labelMatArea(:, end-1) <= theLabelMat(theMax, end-1);
                    theLabelMat = labelMatArea(isSmaller, :);
                    theNbrVtx = nbrVtx(isSmaller, :);
                else
                    % all label vertices can be included
                    theLabelMat = labelMatArea;
                end

                % udpate the candidate vertices for this label (with
                % vertices whose values are under the KEY threshold)
                [~, ~, thisCluIter] = sf_clustervtx(theLabelMat(:, 1), theNbrVtx, '', theVtx);
            end
            % save the local maxima (or the starting vtx)
            gmCell{iClu, ith} = theVtx; % vertex index in Matlab

            % apply different methods for selecting vertices
            switch opts.method
                case {'concentric', 'con-maxresp'}
                    % calculate the accumulative area for the iterations
                    accarea1 = arrayfun(@(x) sum(labelMatArea(thisCluIter <= x,end)), 1:max(thisCluIter));

                    % find the iteration when the area is larger than maxSize for
                    % the first time
                    islarger1 = find(accarea1 > maxSize);

                    % continue if the size of all candidate vertices are smaller
                    % than maxSize
                    if isempty(islarger1)
                        cluVtxCell{iClu, 1} = theLabelMat(:, 1);
                        continue;
                    end

                    % find the key iteration
                    iIter = islarger1(1);

                    %%%%% deal with information for previous iterations
                    % save vertex indices and area for previous iterations (as base)
                    baseVtx = theLabelMat(thisCluIter < iIter, 1);
                    % save the base area
                    baseArea = accarea1(iIter-1);

                    %%%%% deal with information for this iteration
                    baseLabelMat = theLabelMat(thisCluIter == iIter, :);
                    [~, theorder] = sort(abs(baseLabelMat(:, end-1)), opts.sortorder);
                    sortBaseMat = baseLabelMat(theorder, :);

                    % calculate the accumulative areas based on vertex values
                    accarea2 = arrayfun(@(x) sum(sortBaseMat(1:x, end)), ...
                        1:size(sortBaseMat, 1));

                    % identify vertex indices whith which the cluster area is
                    % larger than maxSize
                    tmpArea = baseArea + accarea2;
                    islarger2 = find(tmpArea > maxSize);
                    extraVtx = sortBaseMat(1:islarger2-1, 1);

                    % save all the vertice indices for this cluster
                    % each column is one 'ith'
                    cluVtxCell{iClu, ith} = [baseVtx; extraVtx];

                case {'maxresp'}
                    % the size of the 'refvtx' (local maxima)
                    refvtx = theLabelMat(thisCluIter == 1, 1);
                    thesize = theLabelMat(thisCluIter == 1, end);
                    roivtxUpdate = refvtx;

                    % keep looking for vertices until reach the 'maxSize'
                    while 1
                        % the vertices in the roi now
                        roivtx = roivtxUpdate;

                        % find all neighbor vertices of 'refvtx'
                        tmpNbrVtx = theNbrVtx(ismember(theLabelMat(:, 1), refvtx));
                        thisNbrVtx = unique(vertcat(tmpNbrVtx{:}));
                        % excluded vertices already in the roi (roivtx)
                        thisnbrVtx = setdiff(thisNbrVtx, roivtx);

                        % find the data for neighbor vertices
                        nbrLabelMat = theLabelMat(ismember(theLabelMat(:, 1), thisnbrVtx), :);
                        if isempty(nbrLabelMat)
                            warning('All vertices are included in the cluster now...');
                            roivtxall = roivtx;
                            break;
                        end
                        nbrResp = nbrLabelMat(:, end-1);

                        % sort by values of neighbor vertices
                        [~, sortidx] = sort(abs(nbrResp), opts.sortorder);
                        sortLabelMat = nbrLabelMat(sortidx, :);

                        % only keep the first 'keepratio' vertices
                        isKept = 1:numel(nbrResp) <= max(floor(numel(nbrResp) * opts.keepratio),1);
                        % save the data for kept vertices
                        keptLabelMat = sortLabelMat(isKept, :);

                        % calculate the accumulative areas
                        accarea = arrayfun(@(x) sum(keptLabelMat(1:x, end)), 1:size(keptLabelMat,1))';
                        keptLabelMat = horzcat(keptLabelMat, accarea); %#ok<AGROW>

                        % calculate the size with new vertices
                        islarger = keptLabelMat(:, end) + thesize > maxSize;

                        % break the while loop if the area is large enough
                        % OR all vertices are included in roivtx
                        if any(islarger) || all(ismember(theLabelMat(:, 1), roivtx))
                            % find the vertice with which the total area is
                            % larger than roivtx
                            isFirst = find(islarger, 1);

                            % save the vertices for this cluster
                            roivtxall = [roivtx; keptLabelMat(1: isFirst-1, 1)];
                            break;
                        end

                        % update the size
                        thesize = thesize + keptLabelMat(end, end);
                        % save the all kept vertices in the 'roivtxUpdate'
                        roivtxUpdate = [roivtx; keptLabelMat(:, 1)];

                        % find the reference vertices of roivtx (i.e., the
                        % most peripheral vertices) for next round
                        refvtx = sf_perivtx(roivtxUpdate, faces);

                    end

                    % save the vertices for later use
                    cluVtxCell{iClu, ith} = roivtxall;

            end  % switch method
        end  % iClu  (for each cluster separately)
    end  % ith

    % remove 'ith' if the area of any temporay label is smaller than minSize
    isRemove = cellfun(@(x) any(sum(labelMatArea(ismember(labelMatArea(:,1), x),end)) < opts.minsize, 1), cluVtxCell);
    cluVtxCell(isRemove) = [];
    gmCell(isRemove) = [];

end

%% Visualize, select and save the clusters
% save the label matrix based on the vertex indices for each cluster
labelMatCell = cellfun(@(x) labelMatArea(ismember(labelMatArea(:, 1), x), 1:end-1), cluVtxCell, 'uni', false);

% get the number of cluster labels and 'ith'
[nLabelClu, nTh] = size(labelMatCell);
% create temporary label names
% tempLabelFn = arrayfun(@(x) sprintf('%s.temp%d.label', erase(labelFn, '.label'), x), 1:nLabelClu, 'uni', false);
tmpLabelFn = arrayfun(@(x) sprintf('%s.tmp%d.label', theHemi, x), 1:nLabelClu, 'uni', false);

for iTh = 1:nTh

    % print message for iTh
    fprintf('\nDisplaying the temporary labels... [%d/%d]\n', iTh, nTh);

    % Create temporary files with temporary label names
    labelfile = cellfun(@(x,y) fs_mklabel(x, subjCode, y), labelMatCell(:, nTh+1-iTh), tmpLabelFn', 'uni', false);

    if nLabelClu > 1

        % show all clusters together if there are more than one cluster
        fs_cvn_print1st(sessCode, anaInfo, {[labelFn refLabel tmpLabelFn]}, outPath, ...
            'overlay', opts.overlay, ...
            'visualimg', 'on', 'waitbar', 0, 'gminfo', opts.gminfo, 'surfarea', opts.surfdef, opts.extraopt1st{:});
        %     waitfor(msgbox('Please checking all the sub-labels...'));
        % input the label names
        prompt = {'Please checking all the sub-labels...'};
        dlgtitle = 'Input';
        dims = [1 35];
        definput = {'skip?'};
        checking = inputdlg(prompt,dlgtitle,dims,definput);

        close all;

        if strcmp(checking, 'skip')
            continue;
        end

        % check if there are overlapping between any two clusters
        allComb = nchoosek(1:nLabelClu, 2);
        allPairs = arrayfun(@(x) cluVtxCell(allComb(x, :), nTh+1-iTh), 1:size(allComb, 1), 'uni', false);

        overlapVtx = cellfun(@(x) intersect(x{:}), allPairs, 'uni', false);
        isOverlap = ~cellfun(@isempty, overlapVtx);

        if opts.warnoverlap && any(isOverlap)
            for iOverlap = find(isOverlap)
                % show overlapping between any pair of clusters
                fs_cvn_print1st(sessCode, anaInfo, {[labelFn refLabel tmpLabelFn(allComb(iOverlap, :))]}, outPath, ...
                    'overlay', opts.overlay, ...
                    'visualimg', 'on', 'waitbar', 0, 'gminfo', opts.gminfo, 'surfarea', opts.surfdef, extraOpt{:});
                waitfor(msgbox('There is overlapping between sub-labels...', 'Overlapping...', 'warn'));
                close all;
            end
        end
    end

    % input the label names for each cluster
    for iTempLabel = 1:nLabelClu

        % this label file name (without and with path)
        thisLabelFile = labelfile{iTempLabel};
        thisClusterLabel = tmpLabelFn{iTempLabel};

        % print gm info
        thegm = gmCell(iTempLabel, nTh+1-iTh);
        fprintf(['\n=========================================================' ...
            '\nThe local maxima is %d.\n'], thegm{1});
        if ischar(opts.surfdef) && opts.showgm
            gmcoord = fs_vtx2fsavg(thegm{1}, subjCode, [theHemi '.' opts.surfdef]);
            fprintf('Its MNI305 coordinates on %s are: %s\n', opts.surfdef, sprintf('%f %f %f', gmcoord(:)));
        end

        % display this temporary cluster
        fs_cvn_print1st(sessCode, anaInfo, {[labelFn refLabel thisClusterLabel]}, outPath, ...
            'overlay', opts.overlay, ...
            'visualimg', 'on', 'waitbar', 0, 'gminfo', opts.gminfo, 'surfarea', opts.surfdef, extraOpt{:});

        % input the label names
        prompt = {'Enter the label name for this cluster:'};
        dlgtitle = 'Input';
        dims = [1 35];
        if opts.savesize==1
            tmpStr = erase(labelFn, {'f13.', 'manual.', 'alt.', 'label'});
            definput = {sprintf('%sa%d.label', tmpStr, maxSize)};
        elseif opts.savesize==2
            tmpStr = erase(labelFn, {'manual.', 'alt.'});
            definput = {strrep(tmpStr, 'f13', sprintf('a%d', maxSize))};
        else
            definput = {erase(labelFn, {'f13.', 'manual.', 'alt.'})};
        end
        newlabelname = inputdlg(prompt,dlgtitle,dims,definput);

        close all;

        % rename or remove the temporary label files
        if ~isempty(newlabelname)
            if strcmp(newlabelname, 'skip')
                % do not show all the following labels
                delete(thisLabelFile);
                break;
            elseif endsWith(newlabelname, {'remove', 'rm'})
                delete(thisLabelFile);
            elseif ~strcmp(newlabelname{1}, thisClusterLabel)
                updateLabelFile = strrep(thisLabelFile, thisClusterLabel, newlabelname{1});
                movefile(thisLabelFile, updateLabelFile);
                % save the local maxima file
                if opts.savegm
                    thegmFile = strrep(updateLabelFile, '.label', '.gm');
                    % save the local maxima file
                    fm_mkfile(thegmFile, thegm);

                    % print the message
                    [~, thefn, theext] = fileparts(thegmFile);
                    fprintf('The local maxima file (%s) is saved.\n', [thefn, theext]);
                end
            end
        end

    end  % iTempLabel
end  % iTh

end