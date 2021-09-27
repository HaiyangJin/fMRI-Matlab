function fs_circleroi(subjList, gmList, varargin)
% fs_circleroi(subjList, gmList, varargin)
%
% This function creates circle ROIs for a list of sbujects and global
% maximal files. 
%
% Inputs:
%    subjList        <cell string> list of subject codes in $SUBJECTS_DIR.
%    gmList          <cell string> list of gloal maximal filenames.
%
% Varargin:
%     .dismetric      <string> distance metric along cortical surface.
%                         'euclidean' or 'dijkstra' or 'geodesic' (default)
%     .radius r       <int> } either within radius r (usually in mm), grow
%     .count  c       <int> } the radius to get the nearest c neighbors,
%     .area   a       <int> } grow the radius to get neighbors whose area
%                           } size is less than or equal area a (usually in
%                           } mm^2) or get direct neighbors only (nodes who
%                           } share an edge. These four options are
%                           } mutually exclusive.  
%
% Output:
%     creating new labels.
%
% Created by Haiyang Jin (23-June-2021)

if ~iscell(subjList); subjList = {subjList}; end
if ~iscell(gmList); gmList = {gmList}; end

defaultOpts = struct();
defaultOpts.metric = 'geodesic';
defaultOpts.radius = NaN;
defaultOpts.count = NaN;
defaultOpts.area = NaN;
defaultOpts.extraOpts = {};

opts = fm_mergestruct(defaultOpts, varargin{:});

% which method for roi
if ~isnan(opts.radius)
    radius = opts.radius;
    radiusstr = sprintf('r%d', opts.radius);
elseif ~isnan(opts.count)
    radius = [0 opts.count];
    radiusstr = sprintf('c%d', opts.count);
elseif ~isnan(opts.area)
    radius = [0 Inf opts.area];
    radiusstr = sprintf('a%d', opts.area);
else
    error("Please set any of 'radius', 'count', 'area'.");
end

% label strings added at the end
labelstr = sprintf('.surf.%s.%s.label', opts.metric, radiusstr);


for iSubj = 1:length(subjList)
    thisSubj = subjList{iSubj};
    
    for iVtx = 1:length(gmList)
        thisVtx = gmList{iVtx};
        
        % calculate the roi
        [coordidx,D,scoords, ~] = fs_surf_circleroi(thisSubj, thisVtx, radius, opts.extraOpts{:});
        
        % create the label if the roi is not empty
        if ~isnan(coordidx)
            thisLabelfn = [erase(thisVtx, '.gm') labelstr];
            fs_mklabel(vertcat(coordidx, scoords, D')', thisSubj, thisLabelfn);
        end
    end
end

end
