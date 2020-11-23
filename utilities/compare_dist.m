function [closer, dist, refmean1, refmean2] = compare_dist(coord, ref1, ref2, weights)
% [closer, dist, refmean1, refmean2] = compare_dist(coord, ref1, ref2, weights)
%
% This function compares the distances from certain coordinates to the two
% reference coordinates.
%
% Inputs:
%    coord        <numeric array> P x 3 numeric array. Each row is the XYZ
%                  coordinates for one vertex.
%    ref1         <numeric array> Q x 3 numeric array. Each row is the XYZ
%                  coordinates for one reference coordinates.
%    ref2         <numeric array> same as ref1 but for different reference.
%    weights      <numeric vector> Q x 1 numeric vector. The weights used
%                  to get the mean of reference coordinates. Default is
%                  using the same weights for all reference coordinates.
%
% Outputs:
%    closer       <integer vector> each row is for one coordinates in
%                  'coord'. '1' denotes 'coord' is closer to ref1; '2'
%                  denotes 'coord' is closer to ref2; '0' denotes the
%                  distances are the same.
%    dist         <numeric vector> the difference in distances to ref1 and
%                  ref 2 (i.e., ref1 - ref2).
%    refmean1     <numeric vector> 1 x 3 numeric vector. The mean
%                  coordinates of ref1.
%    refmean2     <numeric vector> 1 x 3 numeric vector. The mean
%                  coordinates of ref2.
%
% Created by Haiyang Jin (23-Nov-2020)

nCoor = size(coord, 1);
nRef = size(ref1, 1);

% apply default weights
if ~exist('weights', 'var') || isempty(weights)
    weights = ones(nRef, 1);
elseif size(weights, 2) ~= 1
    weights = weights';
end
weights = weights/sum(weights);

% calculate the mean ref
refmean1 = (ref1' * weights)';
refmean2 = (ref2' * weights)';

% distance to the two references
dist1 = sqrt(sum((coord - refmean1) .^ 2, 2));
dist2 = sqrt(sum((coord - refmean2) .^ 2, 2));

% difference in dist
dist = dist1 - dist2;

temp1 = dist < 0; % closer to ref1
temp2 = dist > 0; % closer to ref2

temp = [temp2, temp1, zeros(nCoor, 1)];
closer = arrayfun(@(x) 3-find(temp(x, :), 1), 1:size(temp,1))';

end