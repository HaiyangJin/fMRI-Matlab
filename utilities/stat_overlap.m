function ratio = stat_overlap(cluster1, cluster2, overlap, method)
% ratio = stat_overlap(cluster1, cluster2, overlap, method)
%
% Calculates the overlap between two clusters with 'dice' or 'jaccard'
% method (see reference below).
% 
% Inputs:
%    cluster1       <int> number of vertices or voxels.
%                OR <num> the area size of vertices.
%    cluster2       <int> number of vertices or voxels.
%                OR <num> the area size of vertices.
%    overlap        <int> number of vertices or voxels.
%                OR <num> the area size of vertices. Overlap should not
%                    exceed cluster1 or cluster2.
%    method         <str> which method is used to calculate the
%                    overlapping: 'dice' (default) or 'jaccard'.
%
% Output:
%    ratio          <num> a value between 0 and 1. 0 denotes that there is
%                    no overlapping between the two clusters and 1 denotes
%                    that there is perfect overlapping.
%
% Reference:
% Bennett, C. M., & Miller, M. B. (2010). How reliable are the results from
%   functional magnetic resonance imaging? Annals of the New York Academy
%   of Sciences, 1191(1), 133–155.
%   https://doi.org/10.1111/j.1749-6632.2010.05446.x
% Duncan, K. J., Pattamadilok, C., Knierim, I., & Devlin, J. T. (2009).
%   Consistency and variability in functional localisers. NeuroImage,
%   46(4), 1018–1026. https://doi.org/10.1016/j.neuroimage.2009.03.014
%
% Created by Haiyang Jin (2021-12-14)

if nargin < 1
    fprintf('Usage: ratio = stat_overlap(cluster1, cluster2, overlap, method);\n');
    return;
end

if ~exist('method', 'var') || isempty(method)
    method = 'dice'; % or 'jaccard'
elseif isint(method)
    method = num2str(method);
end

assert(overlap <= cluster1+1e-12, 'overlap (%f) should not exceed cluster1 (%f).', ...
    overlap, cluster1);
assert(overlap <= cluster2+1e-12, 'overlap (%f) should not exceed cluster2 (%f).', ...
    overlap, cluster2);

switch method
    case {'dice', '1'}
        ratio = 2 * overlap / (cluster1 + cluster2);

    case {'jaccard', '2'}
        ratio = overlap / (cluster1 + cluster2 - overlap);
end

ratio = max(ratio, 0);
ratio = min(ratio, 1);

end