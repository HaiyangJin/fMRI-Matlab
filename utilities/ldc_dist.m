function dist = ldc_dist(vec_hyper, vec_test, residual1)
% dist = ldc_dist(vec_hyper, vec_test, residual1)
%
% This function computes the representational distance with Linear
% Discriminant Contrast (LDC). This function is built on RDMs_20180530.m in
% https://brunel.figshare.com/articles/dataset/Faces_and_voices_in_the_brain_dataset/6429200/1
% (and http://www.johancarlin.com/pilab-tutorial-2-linear-discriminant-contrast.html).
%
% vec_hyper is used to compute the hyperplane, which will be applied to vec_test to
% compute LDC. For an example with three runs in one session, to compute
% LDC for the first run (vec_test), the estimates of the other two runs
% (concatenated) could (should) be used as vec_hyper. For a concreate example,
% see Tsantani et al., (2019, 2021).
%
% Inputs:
%    vec_hyper  <num array> 2 x Q x M; the two rows are the two vectors of
%                one comparison pair. Q is the feature number of the ROI
%                (e.g., voxel or vertex). Each of the thrid dimension is
%                one comparison pair. Each comparison pair is used to
%                learn the hyperplane, which will be used to apply to
%                vec_test to compute the LDC distance.
%    vec_test   <num array> 2 x Q x N; the two rows are the two vectors of
%                one comparison pair. Q is the feature number of the ROI
%                (e.g., voxel or vertex). Each of the thrid dimension is
%                one comparison pair.
%    residual1  <num mat> P X Q. (What is P? number of volume/TR?)
%
% Output:
%    dist       <num mat> M x N. The LDC distances. Each row is one
%                source comparison pair and each column is one target
%                comparison pair. Each value represents the degree to
%                which each comparison pair (row) in vec_test could be
%                discriminated. Under the null hypothesis, LDC values
%                are distributed ~0 when two patterns cannot be
%                discriminated. Values > 0 indicate higher
%                discriminability of the two response patterns (Walther et
%                al., 2016).
%
% References:
% Nili, H., Wingfield, C., Walther, A., Su, L., Marslen-Wilson, W., &
%   Kriegeskorte, N. (2014). A Toolbox for Representational Similarity
%   Analysis. PLoS Computational Biology, 10(4), e1003553.
%   https://doi.org/10.1371/journal.pcbi.1003553
% Tsantani, M., Kriegeskorte, N., McGettigan, C., & Garrido, L. (2019).
%   Faces and voices in the brain: A modality-general person-identity
%   representation in superior temporal sulcus. NeuroImage, 201,
%   116004. https://doi.org/10.1016/j.neuroimage.2019.07.017
% Tsantani, M., Kriegeskorte, N., Storrs, K., Williams, A. L.,
%   McGettigan, C., & Garrido, L. (2021). FFA and OFA Encode Distinct
%   Types of Face Identity Information. The Journal of Neuroscience,
%   41(9), 1952–1969. https://doi.org/10.1523/JNEUROSCI.1449-20.2020
% Walther, A., Nili, H., Ejaz, N., Alink, A., Kriegeskorte, N., &
%   Diedrichsen, J. (2016). Reliability of dissimilarity measures for
%   multi-voxel pattern analysis. NeuroImage, 137, 188–200.
%   https://doi.org/10.1016/j.neuroimage.2015.12.012
%
% Created by Haiyang Jin (2021-11-09)

% Use the residuals compute the noise-covariance matrix
% Shrink the estimate to a diagonal version
% function is from RSA toolbox
sigma = rsatoolbox_covdiag(residual1);

dist = NaN(size(vec_hyper, 3), size(vec_test, 3));

for i = 1:size(vec_hyper, 3)

    % LDC based on Johan Carlin's code:
    % http://www.johancarlin.com/pilab-tutorial-2-linear-discriminant-contrast.html
    w = (vec_hyper(1,:,i) - vec_hyper(2,:,i)) / sigma;
    w_u = w / sqrt(sum(w.^2));

    % save distance for one source comparison pair
    dist(i, :) = arrayfun(@(x) (vec_test(1,:,x) - vec_test(2,:,x)) * w_u', 1:size(vec_test, 3));

end

end