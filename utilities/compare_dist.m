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
%              OR <string> 'lffa1', 'lffa2', 'rffa1', 'rffa2', 'vwfa1' and
%                  'vwfa2'. The corresponding default reference coordinates
%                  are used ('weights' will be ignored).
%    ref2         Same as ref1 but for different reference. 'ref2' has to
%                  be in the same type and shape of 'ref1'.
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
% Default reference coordinates for FFA1/2:
% Ross, D. A., Tamber-Rosenau, B. J., Palmeri, T. J., Zhang, J., Xu, Y., & 
%   Gauthier, I. (2018). High-resolution Functional Magnetic Resonance 
%   Imaging Reveals Configural Processing of Cars in Right Anterior 
%   Fusiform Face Area of Car Experts. Journal of Cognitive Neuroscience, 
%   30(7), 973?984. https://doi.org/10.1162/jocn_a_01256
% McGugin, R. W., Ryan, K. F., Tamber-Rosenau, B. J., & Gauthier, I. 
%   (2018). The Role of Experience in the Face-Selective Response in Right 
%   FFA. Cerebral Cortex, 28(6), 2071?2084. https://doi.org/10.1093/cercor/bhx113
% McGugin, R. W., & Gauthier, I. (2016). The reliability of individual 
%   differences in face-selective responses in the fusiform gyrus and their
%   relation to face recognition ability. Brain Imaging and Behavior, 
%   10(3), 707?718. https://doi.org/10.1007/s11682-015-9467-4
% McGugin, R. W., Newton, A. T., Gore, J. C., & Gauthier, I. (2014). Robust
%   expertise effects in right FFA. Neuropsychologia, 63, 135?144. 
%   https://doi.org/10.1016/j.neuropsychologia.2014.08.029
% weights = [30, 25, 29, 26];
%
% % lFFA1
% ref_lffa1 = [-39.39, -63.58, -28.71;
%     -41.82, -61.57, -25.01;
%     -39.90, -59.72, -32.06;
%     -39.29, -65.00, -24.62];
% % lFFA2
% ref_lffa2 = [-40.81, -45.56, -30.05;
%     -41.31, -43.14, -26.45;
%     -41.01, -39.65, -30.66;
%     -39.90, -49.66, -23.61];
% % rFFA1
% ref_rffa1 = [38.48 -67.08 -24.26;
%     37.27 -61.33 -23.33;
%     40.71 -58.94 -30.94;
%     36.36 -67.43 -23.33];
% % rFFA2
% ref_rffa2 = [38.99 -46.61 -29.63;
%     37.07 -42.90 -24.77;
%     40.30 -37.55 -29.11;
%     35.56 -51.03 -20.59];
%
% % VWFA (left only)
% ref_vwfa1 = [-39, -72, -18];
% ref_vwfa2 = [-42, -57, -18];
% 
% Created by Haiyang Jin (23-Nov-2020)

% default mean ref coordinates
refCoord = {'lffa1', [-40.0531  -62.4412  -27.7855];
    'lffa2', [-40.7613  -44.4210  -27.8705];
    'rffa1', [38.2918  -63.7099  -25.5899];
    'rffa2', [38.0883  -44.4230  -26.2516];
    'vwfa1', [-39, -72, -18];
    'vwfa2', [-42, -57, -18]};

if ischar(ref1)
    ref1 = refCoord{strcmp(refCoord(:,1), ref1), 2};
    weights = 1;
end

if ischar(ref2)
    ref2 = refCoord{strcmp(refCoord(:,1), ref2), 2};
    weights = 1;
end

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