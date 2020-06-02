function [labelMatCell, cluVtxCell] = fs_updatelabel(labelFn, sessCode, outPath, varargin)
% [labelMatCell, cluVtxCell] = fs_updatelabel(labelFn, sessCode, outPath, varargin)
%
% This function updates the label based on different purposes (see below).
%
% Inputs:
%    labelFn       <string> the label file name.
%    sessCode      <string> session code in $FUNCTIONALS_DIR.
%    outPath       <string> path to the folder for saving some temporary
%                   images.
%
% Options (varargin):
%    'ncluster'    <integer> cluster numbers. Default is 1.
%    'startvtx'    <integer> index of the starting vertex. Default is [].
%                   If 'startvtx' is used, ncluster will be set as 1 and
%                   'lowerthresh' will be set as true. [Not fully
%                   developed. Ths startvtx might not be the global maxima.]
%    'maxsize'     <numeric> the maximum cluster size (mm2) [based on
%                   ?h.white]. Default is 100.
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
%    'lowerthresh' <logical> 1 [default]: release the restriction of the
%                   KEY threshold and all vertices in the label can be
%                   assigned to one cluster. 0: only the vertices whose
%                   values are larger than the KEY threshold can be assigned
%                   to one cluster. [KEY threshold] can be taken as the
%                   largest p-value that forms nCluster clusters.
%    'reflabel'    <cell of string> reference (existing) labels. Default is
%                   '', i.e., no reference lables. Hemisphere information
%                   in the reflabel will be udpated to match labelFn is
%                   necessary.
%    'warnoverlap' <logical> 1 [default]: dispaly if there are overlapping
%                   between clusters; 0: do not dispaly.
%    'smalleronly' <logical> 0 [default]: include vertices ignoring the
%                   values. [Maybe not that useful]. 1: only include
%                   vertices whose values are smaller than that of the
%                   staring vertex in the cluster;
%    'showinfo'    <logical> 0 [default]: show more information; 1: do not
%                   show label information.
%    'extraopt1st' <cell> options used in fs_cvn_print1st.m.
%
% Outputs:
%    labelMatCell  <cell> label matrix for each cluster.
%    cluVtxCell    <cell> vertex indices for each cluster.
%
% Different useage:
% 1: Reduce one label file to a fixed size (on ?h.white) [in mm2].
%    Step 1: Use the vertex whose value is the strongest or custom vertex
%       ('startvtx') as staring point;
%    Step 2: Dilate until the label area reaches a fixed size ('maxsize').
%    Step 3: Save and rename the updated lable files.
%    e.g.:
%       fs_updatelabel(labelFn, sessCode, outPath);
%
% 2: Separate one label file into several clusters ('ncluster'):
%    Step 1: Idenitfy the largest p-value (P) that can separate the label
%        into N clusters.
%    Step 2: Identify the global maxima for each cluster and they will be
%        used as the starting point.
%    Step 3: Get the N clusters and save them as label files.
%    Step 4: Warning if there is overlapping between labels. [These can be
%        solved with fs_setdifflabel.m later.
%    Step 5: Save and rename the updated label files.
%
% Created by Haiyang Jin (14-May-2020)
fprintf('Updating %s for %s...\n', labelFn, sessCode);

%% Deal with inputs
defaultOpts = struct(...
    'ncluster', 1, ...
    'startvtx', [], ...
    'maxsize', 100, ...
    'minsize', 20, ...
    'lagnvtx', 100, ...
    'lagvalue', [], ...
    'maxiter', 20, ...
    'lowerthresh', 1, ...
    'reflabel', '', ...
    'warnoverlap', 1, ...
    'smalleronly', 0, ...
    'showinfo', 0, ...
    'extraopt1st', {{}} ...
    );

opts = fs_mergestruct(defaultOpts, varargin);

nCluster = opts.ncluster;
startVtx = opts.startvtx;
maxSize = opts.maxsize;
minSize = opts.minsize;
lagNVtx = opts.lagnvtx;
lagValue = opts.lagvalue;
maxIter = opts.maxiter;
lowerThresh = opts.lowerthresh;
refLabel = opts.reflabel;
warnoverlap = opts.warnoverlap;
smallerOnly = opts.smalleronly;
showInfo = opts.showinfo;
extraOpt = opts.extraopt1st;

if ~exist('outPath', 'var') || isempty(outPath)
    outPath = fullfile(pwd, 'temporary');
end
if ~exist(outPath, 'dir'); mkdir(outPath); end

if showInfo
    extraOpt = [{'annot', 'aparc', 'showinfo', 1, 'markpeak', 1}, extraOpt];
end

% use startVtx if it is not empty
if ~isempty(startVtx)
    nCluster = 1;
    lowerThresh = 1;
end

% convert refLabel to cell and match hemisphere information
if ischar(refLabel); refLabel = {refLabel}; end
theHemi = fs_2hemi(labelFn);
oldHemi = setdiff({'lh', 'rh'}, theHemi);
refLabel = cellfun(@(x) strrep(x, oldHemi{1}, theHemi), refLabel, 'uni', false);

%% Check if the label is available
% convert sessCode to subjCode
subjCode = fs_subjcode(sessCode);
% read the label
labelMatOrig = fs_readlabel(labelFn, subjCode);

% return if the label is not available.
if isempty(labelMatOrig)
    labelMatCell = {};
    cluVtxCell = {};
    return;
end

% areas for this label
labelarea = fs_labelarea(labelFn, subjCode);
% vertex indices in the label
allVtx = labelMatOrig(:, 1);

if labelarea < maxSize && nCluster == 1
    % skip checking clusters
    warning('The label area (%s) is smaller than the ''maxSize'' (%s).', ...
        labelFn, subjCode);
    cluVtxCell = {allVtx};
    
else
    %% Identify the clusters
    % obtain the neighborhood vertices
    nbrVtx = fs_neighborvtx(labelMatOrig(:, 1), theHemi, subjCode);
    
    % identify all unqiue vertex values
    values = labelMatOrig(:, 5);
    assert(all(values>=0)||all(values<=0), 'Values have to be all positive or all negative.');
    vtxValues = sort(abs(unique(values)));
    
    % obtain the minimum values to be used as cluster-forming thresholds
    if ~isempty(lagValue)
        % use lag values
        [labelMin, labelMax] = bounds(vtxValues);
        fmins = (labelMin:lagValue:labelMax)';
    else
        % use lag vertex number
        fmins = vtxValues(1:lagNVtx:numel(vtxValues));
    end
    
    % apply the maximum iteration for checking clusters
    nIter = numel(fmins);
    if nIter > maxIter
        fmins = fmins(sort(randperm(nIter, maxIter)));
        fprintf('Following thresholds are randomly selected from ''fmin'':\n');
        disp(fmins);
    end
    
    % identify the clusters with all thresholds
    fprintf('Identifying the clusters... [%d/%d]\n', numel(fmins), nIter); 
    [cluNoC, nCluC, iterC] = arrayfun(@(x) fs_clusterlabel(labelFn, subjCode, x), fmins, 'uni', false); %
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
            warning(['Cannot find %d cluster(s) for %s and use %d ' ...
                'clusters now...'], nCluster, sessCode, nCluster + 1);
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
    fprintf('There are %d KEY threshold(s) in total...\n', sum(isKeyTh));

    % save the corresponding ClusterNo and iterations
    keyCluNoC = cluNoC(isKeyTh, :);
    keyIterC = iterC(isKeyTh, :);
    
    %% Try to identify clusters matching the size
    % create empty cell for saving the vertex numbers
    nKeyCluNoC = numel(keyCluNoC);
    cluVtxCell = cell(nCluster, nKeyCluNoC);
    
    for ith = 1:nKeyCluNoC
        
        % this key ClusterNo and iter
        thisCluNo = keyCluNoC{ith, 1};
        thisIter = keyIterC{ith, 1};
        
        % Identify each cluster separately
        for iClu = 1:nCluster
            
            % find vertices (and related information) for this cluster
            isThisClu = thisCluNo == iClu;
            theLabelMat = labelMatOrig(isThisClu, :);
            thisCluIter = thisIter(isThisClu);
            
            % relese the restriction of KEY threshold
            if lowerThresh
                
                % find the index and vertex number for strongest response
                % (i.e., the first iteration)
                [~, theMax] = min(thisCluIter);
                theVtx = theLabelMat(theMax, 1);
                
                % assign the startVtx manually if it is available
                if ~isempty(startVtx)
                    theVtx = startVtx;
                end
                
                if smallerOnly
                    % only values smaller than the starting vertex can be
                    % included in this cluster
                    isSmaller = labelMatOrig(:, 5) <= theLabelMat(theMax, 5);
                    theAllVtx = allVtx(isSmaller, 1);
                    theLabelMat = labelMatOrig(isSmaller, :);
                    theNbrVtx = nbrVtx(isSmaller, :);
                else
                    % all label vertices can be included
                    theAllVtx = allVtx;
                    theLabelMat = labelMatOrig;
                    theNbrVtx = nbrVtx;
                end
                
                % udpate the candidate vertices for this label (with
                % vertices whose values are under the KEY threshold)
                [~, ~, thisCluIter] = fs_clustervtx(theAllVtx, theNbrVtx, '', theVtx);
                
            end
            
            % calculate the accumulative area for the iterations
            accarea1 = arrayfun(@(x) fs_labelarea(labelFn, subjCode, ...
                theLabelMat(thisCluIter <= x, 1)), 1:max(thisCluIter));
            
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
            [~, theorder] = sort(abs(baseLabelMat(:, 5)), 'descend');
            sortBaseMat = baseLabelMat(theorder, :);
            
            % calculate the accumulative areas based on vertex values
            accarea2 = arrayfun(@(x) fs_labelarea(labelFn, subjCode, sortBaseMat(1:x, 1)), ...
                1:size(sortBaseMat, 1));
            
            % identify vertex indices whith which the cluster area is
            % larger than maxSize
            tempArea = baseArea + accarea2;
            islarger2 = find(tempArea > maxSize);
            extraVtx = sortBaseMat(1:islarger2-1, 1);
            
            % save all the vertice indices for this cluster
            % each column is one 'ith'
            cluVtxCell{iClu, ith} = [baseVtx; extraVtx];
            
        end  % iClu  (for each cluster separately)
        
    end  % ith
    
    % remove 'ith' if the area of any temporay label is smaller than
    % minSize
    isRemove = cellfun(@(x) any(fs_labelarea(labelFn, subjCode, x) < minSize, 1), cluVtxCell);
    cluVtxCell(:, isRemove) = [];
    
end

%% Save the clusters
% save the label matrix based on the vertex indices for each cluster
labelMatCell = cellfun(@(x) labelMatOrig(ismember(labelMatOrig(:, 1), x), :), cluVtxCell, 'uni', false);

% get the number of cluster labels and 'ith'
[nLabelClu, nTh] = size(labelMatCell);
% create temporary label names
% tempLabelFn = arrayfun(@(x) sprintf('%s.temp%d.label', erase(labelFn, '.label'), x), 1:nLabelClu, 'uni', false);
tempLabelFn = arrayfun(@(x) sprintf('%s.temp%d.label', theHemi, x), 1:nLabelClu, 'uni', false);

for iTh = 1:nTh
    
    % Create temporary files with temporary label names
    labelfile = cellfun(@(x,y) fs_mklabel(x, subjCode, y), labelMatCell(:, iTh), tempLabelFn', 'uni', false);
    
    if nLabelClu > 1
        
        % show all clusters together if there are more than one cluster
        fs_cvn_print1st(sessCode, '', {[labelFn refLabel tempLabelFn]}, outPath, ...
            'visualimg', 'on', 'waitbar', 0);
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
        allPairs = arrayfun(@(x) cluVtxCell(allComb(x, :), iTh), 1:size(allComb, 1), 'uni', false);
        
        overlapVtx = cellfun(@(x) intersect(x{:}), allPairs, 'uni', false);
        isOverlap = ~cellfun(@isempty, overlapVtx);
        
        if warnoverlap && any(isOverlap)
            for iOverlap = find(isOverlap)
                % show overlapping between any pair of clusters
                fs_cvn_print1st(sessCode, '', {[labelFn refLabel tempLabelFn(allComb(iOverlap, :))]}, outPath, ...
                    'visualimg', 'on', 'waitbar', 0, extraOpt{:});
                waitfor(msgbox('There is overlapping between sub-labels...', 'Overlapping...', 'warn'));
                close all;
            end
        end
    end
    
    % input the label names for each cluster
    for iTempLabel = 1:nLabelClu
        
        % this label file name (without and with path)
        thisLabelFile = labelfile{iTempLabel};
        thisClusterLabel = tempLabelFn{iTempLabel};
        
        % display this temporary cluster
        fs_cvn_print1st(sessCode, '', {[labelFn refLabel thisClusterLabel]}, outPath, ...
            'visualimg', 'on', 'waitbar', 0, extraOpt{:});
        
        % input the label names
        prompt = {'Enter the label name for this cluster:'};
        dlgtitle = 'Input';
        dims = [1 35];
        definput = {erase(labelFn, 'f13.')};
        newlabelname = inputdlg(prompt,dlgtitle,dims,definput);
        
        close all;
        
        % rename or remove the temporary label files
        if ~isempty(newlabelname)
            if endsWith(newlabelname, {'remove', 'rm'})
                delete(thisLabelFile);
            elseif ~strcmp(newlabelname{1}, thisClusterLabel)
                movefile(thisLabelFile, strrep(thisLabelFile, thisClusterLabel, newlabelname{1}));
            end
        end
        
    end  % iTempLabel
    
end  % iTh

end