function overlapT = fs_overlap(labels, subjList, varargin)
% overlapT = fs_overlap(labels, subjList, varargin)
%
% Calculate the cluster overlaps with stat_overlap().
%
% Inputs:
%   labels          <cell str> P x 2 cell. Each row is one pair of label 
%                    files to be compared.
%   subjList        <cell str> subject code in $SUBJECTS_DIR.
%   outPath         <str> where the output file will be saved. 
%
% Varargin:
%   .method         <str> the method to be used to calculate the cluster
%                    overlapping: 'dice' or 'jaccard'. See stat_overlap().
%                    Default is 'dice'.
%   .info           <str> which information to be used to calculate the
%                    cluster overlapping. 'count': use the number of
%                    vertices; 'area': use vertex areas from ?h.area; other
%                    surface (e.g., 'white', 'pial', 'midthickness'): use
%                    vertex areas calcualted from these surface.
%   .outpath        <str> where to save the output file. Default is pwd.
%
% Output:
%   overlapT        <table> the relevant information. 
%
% Created by Haiyang Jin (2021-12-15)
%
% See also:
% stat_overlap

% default settings
defaultOpts = struct(...
    'method', 'dice', ...
    'info', 'count', ...
    'outpath', '');
opts = fm_mergestruct(defaultOpts, varargin);

if ischar(subjList); subjList = {subjList}; end
nSubj = numel(subjList);
nGroup = size(labels, 1);

% to save the output
overlapC = cell(nGroup, nSubj);

for iSubj = 1:nSubj
    
    subjCode = subjList{iSubj};
    
    for iGroup = 1:nGroup

        tmp = struct;
        
        theLabels = labels(iGroup, 1:2);
        % hemisphere information
        hemi = fm_hemi_multi(theLabels, 1);
        % load the two label files
        matCell = cellfun(@(x) fs_readlabel(x, subjCode), theLabels, 'uni', false);

        % check if there is overlapping between the two labels
        vtxLabel1 = matCell{1}(:,1);
        vtxLabel2 = matCell{2}(:,1);
        isoverlap = ismember(vtxLabel1, vtxLabel2);
        overlapVer = vtxLabel1(isoverlap);

        switch opts.info
            case 'count'
                % number of vertices
                cluster1 = size(vtxLabel1, 1);
                cluster2 = size(vtxLabel2, 1);
                overlap = size(overlapVer, 1);

            case {'area', 'white', 'pial', 'midthickness'}
                % vertex areas from surface
                areas = fs_vtxarea({vtxLabel1, vtxLabel2, overlapVer}, ...
                    subjCode, [hemi '.' opts.info]);
                cluster1 = areas(1);
                cluster2 = areas(2);
                overlap = areas(3);

            otherwise
                error('.info (%s) has not been set.', opts.info);
        end

        % save the related information
        tmp.SubjCode = subjCode;
        tmp.Label1 = theLabels{1};
        tmp.Label2 = theLabels{2};
        tmp.Hemi = hemi;
        tmp.info = opts.info;
        tmp.Cluster1 = cluster1; % value of label 1
        tmp.Cluster2 = cluster2; % value of label 2
        tmp.Overlap = overlap;   % value of the overlap
        tmp.Method = opts.method;
        tmp.OverlapRatio = stat_overlap(cluster1, cluster2, overlap, opts.method);

        overlapC{iGroup, iSubj} = tmp;
        clear tmp
    end % iGroup
end % iSubj

% save as table
overlapT = struct2table(vertcat(overlapC{:}));
overlapT = rmmissing(overlapT, 1); % remove empty rows

% where to save the output 
if ~isempty(opts.outpath)
    outPath = fullfile(opts.outpath, 'Reliability_ClusterOverlap');
    fm_mkdir(outPath);
    writetable(overlapT, fullfile(outPath, 'ClusterOverlaps.csv'));
end

end