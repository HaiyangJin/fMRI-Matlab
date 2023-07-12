function labelTable = fs_labelinfo(labelList, subjList, varargin)
% labelTable = fs_labelinfo(labelList, subjList, varargin)
%
% This function gathers the information of the label files.
%
% Inputs:
%    labelList       <str> filename of the label file (with or without
%                     path). If path is included in labelFn, 'subjCode'
%                     and .strupath will be ignored. Default is
%                     'lh.cortex.label'.
%    subjList        <str> subject code in $SUBJECTS_DIR . Default is
%                     fsaverage.
%
% Optional (varargin):
%    'bycluster'     <boo> whether output the information for clusters
%                     separately if there are multiple contiguous clusters
%                     for the label. Default is 1.
%    'fmin'          <num> The (absolute) minimum value for vertices to
%                     be used for summarizing information. Default is 0,
%                     i.e., all vertices will be used.
%    'gminfo'        <boo> 1 [default]: only show gm coordinate
%                     information (but not he maxresp) 2: additionally show
%                     global maxima information (also show maxresp); 0: do
%                     not show gm information.
%    'surf'          <str> surface name which does not include hemisphere
%                     information. Default to 'white'.
%    'isndgrid'      <boo> 1 [default]: all the combinations of
%                     labelList and subjList will be created, i.e.,
%                     summarize all labels in labelList for each subject
%                     separately. 0: only summarize the first label for the
%                     first subject, second label for the second subject,
%                     etc...
%    'saveall'       <b00> 0 [default]: only save information for the
%                     available labels. 1: save information for all labels
%                     files. For unavaiable labels, their information is
%                     saved as empty or NaN.
%    'strudir'       <str> $SUBJECTS_DIR.
%
% Output:
%    labelInfo       <struct> includes information about the label file.
%      .SubjCode       <cell> the input subjCode save as a cell.
%      .Label          <cell> the input labelFn (without path) but save as
%                       a cell.
%      .ClusterNo      <int> the cluster number. If sepCluster is 0,
%                       .ClusterNo is the total number of contiguous
%                       clusters. If sepCluster is 1, .ClusterNo is the
%                       cluster number for each row (cluster).
%      .Max            <num> the peak response value.
%      .VtxMax         <int> vertex index of the peak response.
%      .Size           <num> the size (area) of the label in mm^2.
%      .MNI305         <1x3 num vector> coordinates (XYZ) of VtxMax in
%                       MNI305 (fsaverage) space.
%      .Talairach      <1x3 num vector> coordinates (XYZ) of VtxMax in
%                       Talairach space (use the same method used in
%                       FreeSurfer converting from MNI305 to Talairach).
%      .NVtxs          <int> number of vertices in this label.
%      .fmin           <num> the minimum threshold.
%      .GlobalMax      <int> the global maxima used to create the label.
%
% Created by Haiyang Jin (22-Apr-2020)

if nargin < 1
    fprintf('Usage: labelTable = fs_labelinfo(labelList, subjList, varargin);\n');
    return;
end

defaultOpts = struct(...
    'bycluster', 1, ...
    'fmin', 0, ...
    'gminfo', 1, ...
    'surf', 'white', ...
    'isndgrid', 1, ...
    'saveall', 0, ...
    'strudir', getenv('SUBJECTS_DIR') ...
    );

opts = fm_mergestruct(defaultOpts, varargin{:});
byCluster = opts.bycluster;
fmin = opts.fmin;
gmInfo = opts.gminfo;
isndgrid = opts.isndgrid;
saveAll = opts.saveall;

if ~exist('labelList', 'var') || isempty(labelList)
    labelList = {'lh.cortex.label'};
    warning('''%s'' is loaded by default.', labelList{1});
elseif ischar(labelList)
    labelList = {labelList};
end
if ~exist('subjList', 'var') || isempty(subjList)
    subjList = {'fsaverage'};
    warning('''%s'' is used as ''subjCode'' by default.', subjList{1});
elseif ischar(subjList)
    subjList = {subjList};
end

if isndgrid
    % all the possible combinations
    [tmpList, tmpSubj] = ndgrid(labelList, subjList);
else
    assert(numel(labelList) == numel(subjList), ['The number of labels '...
        'has to be the same as that of subjects when ''ndgrid'' is not used.']);
    tmpList = labelList;
    tmpSubj = subjList;
end

tmpList = tmpList(:);
tmpSubj = tmpSubj(:);

% wait bar
steps = size(tmpList,1);

labelInfoCell = cell(steps,1);

try % try parallel processing

    % set up progress bar
    D1 = parallel.pool.DataQueue;
    h = waitbar(0, 'Preparing for the analysis. Please wait ...');
    afterEach(D1, @nUpdateWaitbar);
    p = 1;

    % pre-set some variable
    surf = opts.surf;
    struDir = opts.strudir;

    % read the label information
    parfor i = 1:steps

        labelInfoCell{i,1} = labelinfo(tmpList{i}, tmpSubj{i}, byCluster, fmin, gmInfo, ...
            surf, saveAll, struDir);

        send(D1, i);
    end

    close(h);

catch
    fprintf('\nNon-parallel processing starts...\n')
    h_non = waitbar(0,'Please wait...');
    % read the label information
    for i = 1:steps

        labelInfoCell{i,1} = labelinfo(tmpList{i}, tmpSubj{i}, byCluster, fmin, gmInfo, ...
            opts.surf, saveAll, opts.strudir);

        % update progress bar
        waitbar(i / steps, ...
            sprintf('SubjCode: %s  Label: %s', tmpSubj{i}, tmpList{i}));
    end
    close(h_non);

end

labelTable = vertcat(labelInfoCell{:});

    function nUpdateWaitbar(~)
    waitbar(p/steps, h, sprintf('fs\\_labelinfo()\n%.2f%% completed...', p/steps*100));
    p = p + 1;
    end

end

%% Obtain the label information separately
function labelInfo = labelinfo(labelFn, subjCode, byCluster, fmin0, ...
    gmInfo, surface, saveall, struDir)

% get the cluster (contiguous)
[clusterNo, nCluster] = fs_clusterlabel(labelFn, subjCode, fmin0);

% read the label file
labelMat = fs_readlabel(labelFn, subjCode, struDir);


Surface = {surface};
if isempty(labelMat)
    if saveall
        SubjCode = {subjCode};
        Label = {labelFn};
        ClusterNo = 0;
        Max = NaN;
        VtxMax = NaN;
        Size = 0;
        MNI305 = {NaN};
        Talairach = {NaN};
        MNI152 = {NaN};
        NVtxs = 0;
        fmin = NaN;

        labelInfo = table(SubjCode, Label, ClusterNo, Max, VtxMax, ...
            Size, MNI305, Talairach, NVtxs, fmin);

        % gmTable
        GlobalMax = NaN;
        MNI305_gm = {NaN};
        Tal_gm = {NaN};
        MNI152_gm = {NaN};

        % save the out information as table
        switch gmInfo
            case 1
                labelInfo = table(SubjCode, Label, ClusterNo, Max, VtxMax, ...
                    GlobalMax, MNI305_gm, Tal_gm, Size, NVtxs, fmin, Surface);
            case 2
                labelInfo = table(SubjCode, Label, ClusterNo, Max, VtxMax, ...
                    GlobalMax, MNI305, Talairach, Size, NVtxs, fmin, MNI305_gm, Tal_gm, Surface);
            case 0
                labelInfo = table(SubjCode, Label, ClusterNo, Max, VtxMax, ...
                    MNI305, Talairach, Size, NVtxs, fmin, Surface);
            case 152
                labelInfo = table(SubjCode, Label, ClusterNo, Max, VtxMax, ...
                    MNI152, Size, NVtxs, fmin, Surface);
            case '152gm'
                labelInfo = table(SubjCode, Label, ClusterNo, Max, VtxMax, ...
                    GlobalMax, MNI152_gm, Size, NVtxs, fmin, Surface);
            case 'all'
                labelInfo = table(SubjCode, Label, ClusterNo, Max, VtxMax, ...
                    GlobalMax, MNI305_gm, Tal_gm, Size, NVtxs, fmin, MNI305, Talairach, MNI152, Surface);
        end
    else
        labelInfo = [];
    end
    return;
end

% update coordinats with `surface` if not empty
surfmat = fs_readsurf([fm_2hemi(labelFn) '.' surface], subjCode);
labelMat(:,2:4) = surfmat(labelMat(:,1), :);

% read the global maxima
gmTable = fs_labelgm(labelFn, subjCode);

% regard it as reference label if nCluster is 0
[~, fn, ext] = fileparts(labelFn);
labelname = [fn ext];
if nCluster == 0
    byCluster = 0;
    nCluster = 1;
    labelname = [labelname '_ref'];
else

end

% output by cluster if needed
if byCluster
    clusters = transpose(1:nCluster);
    matCell = arrayfun(@(x) labelMat(clusterNo == x, :), clusters, 'uni', false);
else
    clusters = nCluster;
    matCell = {labelMat};
end

% maximum response
[~, maxIdx] = cellfun(@(x) max(abs(x(:, 5))), matCell);
maxResp = arrayfun(@(x, y) x{1}(y, 5), matCell, maxIdx);

% coordiantes in RAS, MNI305(fsaverage) and Talairach space
RAS = arrayfun(@(x, y) x{1}(y, 2:4), matCell, maxIdx, 'uni', false);
theMNI305 = cellfun(@(x) fs_self2fsavg(x, subjCode), RAS, 'uni', false);
theTal = cellfun(@mni2tal, theMNI305, 'uni', false);
theMNI152 = cellfun(@fs_fsavg2mni, theMNI305, 'uni', false);
MNI305 = vertcat(theMNI305{:});
Talairach = vertcat(theTal{:});
MNI152 = vertcat(theMNI152{:});

% label area (in mm^2)
labelSize = cellfun(@(x) fs_labelarea(labelFn, subjCode, x(:, 1), surface),...
    matCell, 'uni', true);

%% Create a table to save all the information
% inputs
SubjCode = repmat({subjCode}, numel(clusters), 1);
Label = repmat({labelname}, numel(clusters), 1);

% outinformation
ClusterNo = clusters;
Max = maxResp;
VtxMax = arrayfun(@(x, y) x{1}(y, 1), matCell, maxIdx);
Size = labelSize;
NVtxs = cellfun(@(x) size(x, 1), matCell);
fmin = repmat(fmin0, numel(clusters), 1);

% save gm information
GlobalMax = repmat(gmTable.gm, numel(clusters), 1);
MNI305_gm = repmat(gmTable.MNI305, numel(clusters), 1);
MNI152_gm = repmat(fs_fsavg2mni(MNI305_gm), numel(clusters), 1);
Tal_gm = repmat(gmTable.Talairach, numel(clusters), 1);

% save the out information as table
switch gmInfo
    case 1
        labelInfo = table(SubjCode, Label, ClusterNo, Max, VtxMax, ...
            GlobalMax, MNI305_gm, Tal_gm, Size, NVtxs, fmin, Surface);
    case 2
        labelInfo = table(SubjCode, Label, ClusterNo, Max, VtxMax, ...
            GlobalMax, MNI305, Talairach, Size, NVtxs, fmin, MNI305_gm, Tal_gm, Surface);
    case 0
        labelInfo = table(SubjCode, Label, ClusterNo, Max, VtxMax, ...
            MNI305, Talairach, Size, NVtxs, fmin, Surface);
    case 152
        labelInfo = table(SubjCode, Label, ClusterNo, Max, VtxMax, ...
            MNI152, Size, NVtxs, fmin, Surface);
    case '152gm'
        labelInfo = table(SubjCode, Label, ClusterNo, Max, VtxMax, ...
            GlobalMax, MNI152_gm, Size, NVtxs, fmin, Surface);
    case 'all'
        labelInfo = table(SubjCode, Label, ClusterNo, Max, VtxMax, ...
            GlobalMax, MNI305_gm, Tal_gm, Size, NVtxs, fmin, MNI305, Talairach, MNI152, Surface);
end

end