function dist = rsa_ldc(vec_src, vec_trg, residual)
% dist = rsa_ldc(vec_src, vec_trg, residual)
%
% This function computes the representational distance with Linear
% Discriminant Contrast (LDC). This function is built on RDMs_20180530.m in
% https://brunel.figshare.com/articles/dataset/Faces_and_voices_in_the_brain_dataset/6429200/1
% (and potentially http://www.johancarlin.com/pilab-tutorial-2-linear-discriminant-contrast.html).
% 
% Inputs:
%    vec_src    <cell> M x 2; each cell element is 1 x Q num vector and
%                each row is one comparison pair (M in total). Q is the
%                feature number of the ROI.
%    vec_trg    <cell> N x 2; each cell element is 1 x Q num vector and
%                each row is one comparison pair (N in total).
%    residual   <num array> P X Q. (What is P? number of volume/TR?)
%
% Output:
%    dist       <num array> M x N. The LDC distances. Each row is one 
%                source comparison pair and each column is one target 
%                comparison pair.
%
% References:
% Nili, H., Wingfield, C., Walther, A., Su, L., Marslen-Wilson, W., & 
%   Kriegeskorte, N. (2014). A Toolbox for Representational Similarity 
%   Analysis. PLoS Computational Biology, 10(4), e1003553. 
%   https://doi.org/10.1371/journal.pcbi.1003553
% Tsantani, M., Kriegeskorte, N., Storrs, K., Williams, A. L., 
%   McGettigan, C., & Garrido, L. (2021). FFA and OFA Encode Distinct 
%   Types of Face Identity Information. The Journal of Neuroscience, 
%   41(9), 1952–1969. https://doi.org/10.1523/JNEUROSCI.1449-20.2020
%
% Created by Haiyang Jin (2021-11-09)

% Use the residuals compute the noise-covariance matrix 
% Shrink the estimate to a diagonal version
% function is from RSA toolbox
sigma = rsatoolbox_covdiag(residual);

m_cell = cell(size(vec_src, 1), 1);

for i = 1:size(vec_src, 1)

    % LDC based on Johan Carlin's code:
    % http://www.johancarlin.com/pilab-tutorial-2-linear-discriminant-contrast.html
    w_src = (vec_src{i,1} - vec_src{i,2}) / sigma;
    w_srcu = w_src / sqrt(sum(w_src.^2));

    % save distance for one source comparison pair
    m_cell{i, 1} = arrayfun(@(x) (vec_trg{x,1} - vec_trg{x,2}) * w_srcu', 1:size(vec_trg, 1));

end

% each row is one source comparison pair and each column is one target comparison pair
dist = vertcat(m_cell{:});

end