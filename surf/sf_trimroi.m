function [cluVtxCell, gmCell] = sf_trimroi(labelMat, surfDef, varargin)
% [labelMatCell, cluVtxCell] = sf_trimroi(labelFn, subjCode, outPath, varargin)
%
% This function updates the label based on different purposes (see below).
%
% Inputs:
%    labelMat      <num array> the first column is the vertex indices and
%                   the last column is the functional results (e.g.,
%                   t-value).
%    surfDef       <cell> subject code in $SUBJECTS_DIR.
%    outPath       <string> path to the folder for saving some temporary
%                   images.
%
% Options (varargin):
%    'method'      <string> different methods for dilating the global
%                   maxima to a cluster/roi. The options are 'concentric',
%                   'maxresp'[default], or 'con-maxresp'. More see below.
%    'ncluster'    <integer> cluster numbers. Default is 1.
%    'startvtx'    <integer> index of the starting vertex. This should be
%                   the vertex index in the Matlab (i.e., already + 1).
%                   Default is []. If 'startvtx' is used, ncluster will be
%                   set as 1 and 'lowerthresh' will be set as true. [Not
%                   fully developed. Ths startvtx might not be the global
%                   maxima.] Note: when 'startvtx' is not empty and
%                   'savegm' is 1, startvtx will be saved as 'gmfn'.
%    'maxsize'     <numeric> the maximum cluster size (mm2) [based on
%                   ?h.white]. Default is 100.
%    'savesize'    <logical> 0 [default]: do not save the area size
%                   information in the label file name; 1: save the area
%                   size information.
%    'minsize'     <numeric> the minimum cluster size (mm2) [based on
%                   ?h.white]. Default is 20 (arbitrary number).
%    'lagnvtx'     <integer> number (lagvtx-1) of vertex values to be
%                   skipped for checking cluster numbers with certain
%                   threshold (value). Default is 100. e.g., if there are
%                   200 vertices in the label, The value of vertices
%                   (1:100:200) will be used as cluster-forming thresholds.
%    'lagvalue'    <numeric> lag of values to be skipped for checking
%                   cluster numbers. Default is []. e.g., if the values in
%                   the label range from 1.3 to 8. The values of 1.3:.1:8
%                   will be used as clustering-forming threshold.
%                   'lagvalue' will be used if it is not empty.
%    'maxiter'     <numeric> the maximum number of iterations for
%                   checking clusters with different clusterwise
%                   "threshold". Default is 20. If the interation (i.e.,
%                   nIter) is larger than 'maxiter' after applying
%                   'lagnvtx' and 'lagvalue' , 'maxiter' of 'fmins' will be
%                   selected randomly. [If the value is too large, it will
%                   take too long to identify the clusters.]
%    'keepratio'   <numeric> how much of data will be kept when 'maxresp'
%                   method is used. Default is 0.5.
%    'lowerthresh' <logical> 1 [default]: release the restriction of the
%                   KEY threshold, and all vertices in the label can be
%                   assigned to one cluster. 0: only the vertices whose
%                   values are larger than the KEY threshold can be assigned
%                   to one cluster. [KEY threshold] can be taken as the
%                   largest p-value that forms nCluster clusters.
%
% Outputs:
%    labelMatCell  <cell> label matrix for each cluster.
%    cluVtxCell    <cell> vertex indices for each cluster.
%
% Different usage:
% 1: Reduce one label file to a fixed size (on ?h.white) [in mm2].
%    Step 1: Use the vertex whose value is the strongest or custom vertex
%       ('startvtx') as staring point;
%    Step 2: Dilate until the label area reaches a fixed size ('maxsize').
%    Step 3: Save and rename the updated lable files.
%    e.g.:
%       fs_trimlabel(labelFn, sessCode, outPath);
%
% 2: Separate one label file into several clusters ('ncluster'):
%    Step 1: Idenitfy the largest p-value (P) that can separate the label
%        into N clusters.
%    Step 2: Identify the global maxima for each cluster and they will be
%        used as the starting point.
%    Step 3: Dilate until the label area reaches a fixed size ('maxsize').
%    Step 4: Rename and save the updated lable files.
%    Step 5: Warning if there is overlapping between labels. [The
%        overlapping can be removed with fs_setdifflabel.m later.]
%    Step 6: Save and rename the updated label files.
%
% Methods for 'dilating the global maxima':
% 1. 'concentric'
%    Step 1: Identify the neighbor vertices of the global maxima and
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
%    Step 1: Identify the neighbor vertices of the global maxima and
%        only keep the first 'keepratio' (e.g., 50%) of the most active
%        neighbor vertices.
%    Step 2: Identify the neighbor vertices of the vertices in Step 1 and,
%        again, only keep the first 'keepratio' (e.g., 50%) of the most
%        active neighbor vertices.
%    Step 3: Keep including more neighbor vertices until the total area
%        is close enough to but not exceed 'maxsize'.
%    Note: The global maxima is not necessarily in the center.
%    Special note: when 'keepratio' is 100%, the final label will be quite
%        similar to (or the same as) that generated by 'concentric' for the
%        same global maxima.
%
% 3. 'con-maxresp'
%    [not fully developed.]
%    Step 1: Use 'concentric' method to generate the cluster/roi for the
%        global maxima.
%    Step 2: Within this cluster, select the most active vertices as the
%        final label.
%    Note: the vertices in the final label are not necessarily contiguous.
%
% Created by Haiyang Jin (14-May-2020)

%% Deal with inputs
defaultOpts = struct(...
    'method', 'maxresp', ...
    'ncluster', 1, ...
    'startvtx', [], ...
    'gmfn', '', ...
    'savegm', 1, ...
    'maxsize', 100, ...
    'savesize', 0, ...
    'minsize', 20, ...
    'lagnvtx', 100, ...
    'lagvalue', [], ...
    'maxiter', 20, ...
    'keepratio', 0.5, ...
    'lowerthresh', 1, ...
    'smalleronly', 0 ...
    );

opts = fm_mergestruct(defaultOpts, varargin);

nCluster = opts.ncluster;
startVtx = opts.startvtx;
maxSize = opts.maxsize;
lowerThresh = opts.lowerthresh;

% surface definition related
[vertices, faces] = surfDef{:};

%% Check if the label is available
% return if the label is not available.
if isempty(labelMat)
    gmCell = {};
    cluVtxCell = {};
    warning('labelMat is empty.');
    return;
end

vtxarea=surfing_surfacearea(vertices,faces);
labelMatArea = horzcat(labelMat, vtxarea(labelMat(:,1)));

% sanity check: there should be only 1 cluster
[~, theNClu] = sf_clusterlabel(labelMatArea, faces);
assert(theNClu==1, 'There are more than one cluster in the label.');

% areas for this label
if sum(labelMatArea(:,end)) < maxSize && nCluster == 1
    % skip checking clusters
    warning('The label area is smaller than the ''maxSize''.');
    cluVtxCell = {labelMatArea(:, 1)};

    % find the global maxima
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
        vtxValues = sort(abs(unique(labelMatArea(:, end-1))));

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
            fmins = fmins(sort(randperm(nIter, opts.maxiter)));
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
    % create empty array (-1) for saving the global maxima
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
            % global maxima].
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
            % save the global maxima (or the starting vtx)
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
                    [~, theorder] = sort(abs(baseLabelMat(:, end-1)), 'descend');
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
                    % the size of the 'refvtx' (global maxima)
                    refvtx = theLabelMat(thisCluIter == 1, 1);
                    thesize = vtxarea(thisCluIter == 1);
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
                        [~, sortidx] = sort(abs(nbrResp), 'descend');
                        sortLabelMat = nbrLabelMat(sortidx, :);

                        % only keep the first 'keepratio' vertices
                        isKept = 1:numel(nbrResp) <= ceil(numel(nbrResp) * opts.keepratio);
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

end