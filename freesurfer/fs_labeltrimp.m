function fs_labeltrimp(labelFn, sessCode, thresh, varargin)
% fs_labeltrimp(labelFn, sessCode, thresh, varargin)
%
% Trim the label with a higher threshold (smaller p-value).
%
% Inputs:
%    labelFn        <str> the filename of the label file to be trimmed.
%    sessCode       <str> session code in $FUNCTIONALS_DIR.
%    thresh         <num> the threshold to be used to trim the label.
%
% Varargin:
%    'outpath'      <str> the folder to save some temporay files. Default
%                    is '', and it will be deleted automatically.
%    'surfdef'      <cell> {vertices, faces}.
%                OR <str> the surface string, e.g., 'white', 'pial'. The
%                    hemisphere information will be read from labelFn.
%    'analysis'     <str> the analysis used to create the label. If 
%                    'overlay' is not empty, 'analysis' will be ignored.
%    'overlay'      <num vec> result (e.g., FreeSurfer p-values) to be 
%                    displayed on the surface. It has to be the result for 
%                    the whole 'surfdef'. Default is ''. 
%    'reflabel'    <cell str> reference (existing) labels. Default is
%                   '', i.e., no reference lables. Hemisphere information
%                   in the reflabel will be udpated to match labelFn is
%                   necessary.
%    'gminfo'      <boo> 0: do not show global maxima information;
%                   1 [default]: only show the global maxima information,
%                   but not the maxresp; 2: show both global maxima and 
%                   maxresp information.
%    'warnoverlap' <boo> 1 [default]: dispaly if there are overlapping
%                   between clusters; 0: do not dispaly. [This should not
%                   happen.]
%    'extraopt1st' <cell> options used in fs_cvn_print1st.m.
%
% Output:
%    a trimmed label saved in the label\ folder.
%
% Created by Haiyang Jin (2022-03-15)

%% Deal with inputs
if nargin < 1
    fprintf('Usage: fs_labeltrimp(labelFn, sessCode, thresh, varargin);\n');
    return;
end

fprintf('\nThe label to be trimmed is %s...\n', labelFn);

defaultOpts = struct(...
    'outpath', '', ...
    'surfdef', 'white', ...
    'analysis', '', ...
    'overlay', '', ...
    'reflabel', '', ...
    'gminfo', 0, ...
    'warnoverlap', 1, ...
    'extraopt1st', {{}} ...
    );

opts = fm_mergestruct(defaultOpts, varargin{:});


if isempty(opts.outpath)
    outPath = fullfile(pwd, sprintf('tmp_labeltrimp_%d', now));
    toremove = 1;
else
    outPath = opts.outpath;
    toremove = 0;
end

subjCode = fs_subjcode(sessCode, 0);

% convert refLabel to cell and match hemisphere information
refLabel = opts.reflabel;
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

%% Identify candidaite rois
% read label
labelMat = fs_readlabel(labelFn, subjCode);

% make sure the p-value is FreeSurfer p-value
thresh = fs_pvalue(thresh, 'fsp');
assert(thresh*10>fm_2sig(labelFn), ['<Thresh> (%d) should be more strigent than ' ...
    'that in the label (%d).'], thresh, fm_2sig(labelFn)/10);
threshstr = sprintf('f%2d', thresh*10);

% detect the number of clusters after applying the new threshold
[clusterNo, nCluster] = fs_clusterlabel(labelFn, subjCode, thresh);

cluVtxCell = arrayfun(@(x) labelMat(clusterNo==x, 1), 1:nCluster, 'uni', false)';

%% Visualize the candidate rois
% save the label matrix based on the vertex indices for each cluster
labelMatCell = cellfun(@(x) labelMat(ismember(labelMat(:, 1), x(:)), :), ...
    cluVtxCell, 'uni', false);

% get the number of cluster labels and 'ith'
[nLabelClu, nTh] = size(labelMatCell);

% create temporary label names
% tempLabelFn = arrayfun(@(x) sprintf('%s.temp%d.label', erase(labelFn, '.label'), x), 1:nLabelClu, 'uni', false);
tmpLabelFn = arrayfun(@(x) sprintf('%s.tmp%d.label', theHemi, x), ...
    1:nLabelClu, 'uni', false)';

for iTh = 1:nTh

    % print message for iTh
    fprintf('\nDisplaying the temporary labels... [%d/%d]\n', iTh, nTh);

    % Create temporary files with temporary label names
    labelfile = cellfun(@(x,y) fs_mklabel(x, subjCode, y), ...
        labelMatCell(:, iTh), tmpLabelFn, 'uni', false);

    if nLabelClu > 1

        % show all clusters together if there are more than one cluster
        fs_cvn_print1st(sessCode, anaInfo, {[labelFn; refLabel; tmpLabelFn]}, outPath, ...
            'overlay', opts.overlay, ...
            'visualimg', 'on', 'waitbar', 0, 'gminfo', opts.gminfo, ...
            'surfarea', opts.surfdef, opts.extraopt1st{:});
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

        overlapVtx = cellfun(@(x) intersect(x{1}(:,1), x{2}(:,1)), allPairs, 'uni', false);
        isOverlap = ~cellfun(@isempty, overlapVtx);

        if opts.warnoverlap && any(isOverlap)
            for iOverlap = find(isOverlap)
                % show overlapping between any pair of clusters
                fs_cvn_print1st(sessCode, anaInfo, {[labelFn; refLabel; ...
                    tmpLabelFn(allComb(iOverlap, :))]}, outPath, ...
                    'overlay', opts.overlay, ...
                    'visualimg', 'on', 'waitbar', 0, 'gminfo', opts.gminfo, ...
                    'surfarea', opts.surfdef, opts.extraopt1st{:});
                waitfor(msgbox('There is overlapping between sub-labels...', ...
                    'Overlapping...', 'warn'));
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
        fs_cvn_print1st(sessCode, anaInfo, {[labelFn refLabel thisClusterLabel]}, outPath, ...
            'overlay', opts.overlay, ...
            'visualimg', 'on', 'waitbar', 0, 'gminfo', opts.gminfo, ...
            'surfarea', opts.surfdef, opts.extraopt1st{:});

        % input the label names
        prompt = {'Enter the label name for this cluster:'};
        dlgtitle = 'Input';
        dims = [1 35];
        definput = {strrep(labelFn, fm_2thresh(labelFn), threshstr)};
        newlabelname = inputdlg(prompt,dlgtitle,dims,definput);

        close all;

        % rename or remove the temporary label files
        if ~isempty(newlabelname)
            if endsWith(newlabelname, {'remove', 'rm'})
                delete(thisLabelFile);
            elseif endsWith(newlabelname, 'skip')
                % do not show all the following labels
                delete(thisLabelFile);
                return;
            elseif ~strcmp(newlabelname{1}, thisClusterLabel)
                updateLabelFile = strrep(thisLabelFile, thisClusterLabel, newlabelname{1});
                movefile(thisLabelFile, updateLabelFile);
            end
        end

    end  % iTempLabel
end  % iTh

if toremove && exist('outPath', 'dir')
    rmdir(outPath, 's');
end

end