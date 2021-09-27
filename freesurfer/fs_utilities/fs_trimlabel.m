function [labelMatCell, cluVtxCell] = fs_trimlabel(labelFn, sessCode, outPath, varargin)
% [labelMatCell, cluVtxCell] = fs_trimlabel(labelFn, sessCode, outPath, varargin)
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
%    'gmfn'        <string> the filename of the global maxima to be used.
%                   Default is '' (empty) and no global maxima saved before
%                   will be used. if 'gmfn' is not empty and the file
%                   exists, the vertex index in the file will be used as
%                   the global maxima and 'startvtx' will be ignored.
%    'savegm'      <logical> 1 [default]: save the global maxima (matlab
%                   vertex index) used for creating the updated label as a
%                   file. Its filename will be the same as the label
%                   filename (replace '.label' as '.gm'. 0: do not save the
%                   global maxima.
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
%    'peakonly'    <logical> 1 [default]: only show the peak when identify
%                   global maxima; 0: show the outline of the label.
%    'showinfo'    <logical> 0 [default]: show more information; 1: do not
%                   show label information.
%    'extraopt1st' <cell> options used in fs_cvn_print1st.m.
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
% 1. 'concentric' [default]
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
% 2. 'maxresp'
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
fprintf('\nUpdating %s for %s...\n', labelFn, sessCode);

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
    'reflabel', '', ...
    'warnoverlap', 1, ...
    'smalleronly', 0, ...
    'peakonly', 1, ...
    'showinfo', 0, ...
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
subjCode = fs_subjcode(sessCode);

if ~exist('outPath', 'var') || isempty(outPath)
    outPath = fullfile(pwd, 'temporary');
end
if ~exist(outPath, 'dir'); mkdir(outPath); end

if opts.showinfo
    extraOpt = [{'annot', 'aparc', 'showinfo', 1, 'markpeak', 1}, extraOpt];
end

% use the global maxima saved before as 'startVtx' if needed
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
theHemi = fs_2hemi(labelFn);
oldHemi = setdiff({'lh', 'rh'}, theHemi);
refLabel = cellfun(@(x) strrep(x, oldHemi{1}, theHemi), refLabel, 'uni', false);

% only show global maxima for selecting roi
if opts.peakonly
    extraOpt = [{'peakonly', 1}, extraOpt];
    overlay = sprintf('nooverlay.%s', theHemi);
else
    overlay = sprintf('labeloverlay.%s', theHemi);
end

%% Check if the label is available
% read the label
labelMatOrig = fs_readlabel(labelFn, subjCode);

% return if the label is not available.
if isempty(labelMatOrig)
    labelMatCell = {};
    cluVtxCell = {};
    warning('Cannot find the label or the label is empty.');
    return;
end

% sanity check: there should be only 1 cluster
[~, theNClu] = fs_clusterlabel(labelFn, subjCode);
assert(theNClu==1, 'There are more than one cluster in the label.');

% areas for this label
labelarea = fs_labelarea(labelFn, subjCode);

if labelarea < maxSize && nCluster == 1
    % skip checking clusters
    warning('The label area (%s) is smaller than the ''maxSize'' (%s).', ...
        labelFn, subjCode);
    cluVtxCell = {labelMatOrig(:, 1)};
    
    % find the global maxima
    [~, theMax] = max(abs(labelMatOrig(:, 5)));
    gmCell = {labelMatOrig(theMax, 1)};
    
else
    %% Identify the clusters
    % obtain the neighbor vertices
    nbrVtx = fs_neighborvtx(labelMatOrig(:, 1), theHemi, subjCode);
        
    if ~isempty(startVtx)
        % use startVtx if it is not empty
        nCluster = 1;
        lowerThresh = 1;
        
        keyCluNoC{1,1} = ones(size(labelMatOrig, 1), 1);
        keyIterC = keyCluNoC;   
        
    else
        % identify all unqiue vertex values
        vtxValues = sort(abs(unique(labelMatOrig(:, 5))));
        
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
            theLabelMat = labelMatOrig(isThisClu, :);
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
                    isSmaller = labelMatOrig(:, 5) <= theLabelMat(theMax, 5);
                    theLabelMat = labelMatOrig(isSmaller, :);
                    theNbrVtx = nbrVtx(isSmaller, :);
                else
                    % all label vertices can be included
                    theLabelMat = labelMatOrig;
                end
                
                % udpate the candidate vertices for this label (with
                % vertices whose values are under the KEY threshold)
                [~, ~, thisCluIter] = fs_clustervtx(theLabelMat(:, 1), theNbrVtx, '', theVtx);
            end
            % save the global maxima (or the starting vtx)
            gmCell{iClu, ith} = theVtx; % vertex index in Matlab
            
            % apply different methods for selecting vertices
            switch opts.method
                case {'concentric', 'con-maxresp'}
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
                    tmpArea = baseArea + accarea2;
                    islarger2 = find(tmpArea > maxSize);
                    extraVtx = sortBaseMat(1:islarger2-1, 1);
                    
                    % save all the vertice indices for this cluster
                    % each column is one 'ith'
                    cluVtxCell{iClu, ith} = [baseVtx; extraVtx];
                    
                case {'maxresp'}
                    % the size of the 'refvtx' (global maxima)
                    refvtx = theLabelMat(thisCluIter == 1, 1);
                    thesize = fs_labelarea(labelFn, subjCode, refvtx);
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
                        nbrResp = nbrLabelMat(:, 5);
                        
                        % sort by values of neighbor vertices
                        [~, sortidx] = sort(abs(nbrResp), 'descend');
                        sortLabelMat = nbrLabelMat(sortidx, :);
                        % only keep the first 'keepratio' vertices
                        isKept = 1:numel(nbrResp) <= ceil(numel(nbrResp) * opts.keepratio);
                        % save the data for kept vertices
                        keptLabelMat = sortLabelMat(isKept, :);
                        
                        % calculate the accumulative areas
                        keptLabelMat(:, 6) = arrayfun(@(x) sum(fs_labelarea(...
                            labelFn, subjCode, keptLabelMat(1:x, 1))), ...
                            1:size(keptLabelMat, 1));
                        
                        % calculate the size with new vertices
                        islarger = keptLabelMat(:, 6) + thesize > maxSize;
                        
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
                        thesize = thesize + keptLabelMat(end, 6);
                        % save the all kept vertices in the 'roivtxUpdate'
                        roivtxUpdate = [roivtx; keptLabelMat(:, 1)];
                        
                        % find the reference vertices of roivtx (i.e., the
                        % most peripheral vertices) for next round
                        refvtx = fs_perivtx(roivtxUpdate, theHemi, subjCode);
                        
                    end
                    
                    % save the vertices for later use
                    cluVtxCell{iClu, ith} = roivtxall;
                    
            end  % switch method
        end  % iClu  (for each cluster separately)
    end  % ith
    
    % remove 'ith' if the area of any temporay label is smaller than minSize
    isRemove = cellfun(@(x) any(fs_labelarea(labelFn, subjCode, x) < opts.minsize, 1), cluVtxCell);
    cluVtxCell(isRemove) = [];
    gmCell(isRemove) = [];
    
end

%% Visualize, select and save the clusters
% save the label matrix based on the vertex indices for each cluster
labelMatCell = cellfun(@(x) labelMatOrig(ismember(labelMatOrig(:, 1), x), :), cluVtxCell, 'uni', false);

% get the number of cluster labels and 'ith'
[nLabelClu, nTh] = size(labelMatCell);
% create temporary label names
% tempLabelFn = arrayfun(@(x) sprintf('%s.temp%d.label', erase(labelFn, '.label'), x), 1:nLabelClu, 'uni', false);
tmpLabelFn = arrayfun(@(x) sprintf('%s.tmp%d.label', theHemi, x), 1:nLabelClu, 'uni', false);

for iTh = 1:nTh
    
    % print message for iTh
    fprintf('\nDisplaying the temporary labels... [%d/%d]\n', iTh, nTh);
    
    % Create temporary files with temporary label names
    labelfile = cellfun(@(x,y) fs_mklabel(x, subjCode, y), labelMatCell(:, iTh), tmpLabelFn', 'uni', false);
    
    if nLabelClu > 1
        
        % show all clusters together if there are more than one cluster
        fs_cvn_print1st(sessCode, overlay, {[labelFn refLabel tmpLabelFn]}, outPath, ...
            'visualimg', 'on', 'waitbar', 0, 'gminfo', 0);
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
        
        if opts.warnoverlap && any(isOverlap)
            for iOverlap = find(isOverlap)
                % show overlapping between any pair of clusters
                fs_cvn_print1st(sessCode, overlay, {[labelFn refLabel tmpLabelFn(allComb(iOverlap, :))]}, outPath, ...
                    'visualimg', 'on', 'waitbar', 0, 'gminfo', 0, extraOpt{:});
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
        
        % display this temporary cluster
        fs_cvn_print1st(sessCode, overlay, {[labelFn refLabel thisClusterLabel]}, outPath, ...
            'visualimg', 'on', 'waitbar', 0, 'gminfo', 0, extraOpt{:});
        
        % input the label names
        prompt = {'Enter the label name for this cluster:'};
        dlgtitle = 'Input';
        dims = [1 35];
        if opts.savesize
            tmpStr = erase(labelFn, {'f13.', 'manual.', 'alt.', 'label'});
            definput = {sprintf('%sa%d.label', tmpStr, maxSize)};
        else
            definput = {erase(labelFn, {'f13.', 'manual.', 'alt.'})};
        end
        newlabelname = inputdlg(prompt,dlgtitle,dims,definput);
        
        close all;
        
        % rename or remove the temporary label files
        if ~isempty(newlabelname)
            if endsWith(newlabelname, {'remove', 'rm'})
                delete(thisLabelFile);
            elseif ~strcmp(newlabelname{1}, thisClusterLabel)
                updateLabelFile = strrep(thisLabelFile, thisClusterLabel, newlabelname{1});
                movefile(thisLabelFile, updateLabelFile);
                % save the global maxima file
                if opts.savegm
                    thegm = gmCell(iTempLabel, iTh);
                    thegmFile = strrep(updateLabelFile, '.label', '.gm');
                    % save the global maxima file
                    fm_createfile(thegmFile, thegm);
                    
                    % print the message
                    [~, thefn, theext] = fileparts(thegmFile);
                    fprintf('The global maxima file (%s) is saved.\n', [thefn, theext]);
                end
            end
        end
        
    end  % iTempLabel
end  % iTh

end