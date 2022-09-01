function rdm = rsa_ldc(mat_hyper, mat_test, residual_hyper)
% rdm = rsa_ldc(mat_hyper, mat_test, residual_hyper)
%
% This function computes Linear Discriminant Contrast distance for the
% input matrices. mat_hyper is used to make the hyperplane and mat_test is
% used to test the pairwise distance.
%
% Inputs:
%    mat_hyper  <num array> I x Q x R; each row is one stimulus/condition and
%                each column is one feature (e.g., voxel or vertex). 
%                each pair of rows in {mat_hyper} will be used to make the 
%                hyperplane. R is the number of runs if applicable,
%                {mat_hypyer} will be averaged across/along R. 
%    mat_test   <num mat> I x Q x S; the first and second dimensions are
%                stimulus/condition and feature. It should be different
%                data set from {mat_hyper}, e.g., data from different runs.
%                And the orders of I here should match that in mat_hyper.
%                S is applicable when multiple data sets will be tested.
%    residual_hyper  <num mat> P X Q. The residuals for {vec_hyper} after 
%                fitting the model. P seems to be the number of TR, i.e., 
%                data points collected. Q is the feature number of the ROI
%                (e.g., voxel or vertex).
%
% Output:
%    rdm        <num array> I x R x S; each row and each column is one
%                stimulus/condition.
%
% See also:
% dist_ldc

if nargin < 1
    fprintf('Usage: rdm = rsa_ldc(mat_hyper, mat_test, residual_hyper);\n');
    return
end

% average across the third dimensions
mat_hyper = mean(mat_hyper, 3);

% number of conditions to be compared
ncond = size(mat_hyper, 1);

% initial NaN output
rdm = NaN(ncond, ncond, size(mat_test,3));

% compare for each pair
for cond1 = 1:ncond
    for cond2 = (cond1+1):ncond

        % vectors used to make hyperplane
        vec_hyper = mat_hyper([cond1,cond2], :);
        % vectors to be tested
        vec_test = mat_test([cond1,cond2], :, :);
        % distances
        dist = dist_ldc(vec_hyper, vec_test, residual_hyper);

        rdm(cond2,cond1,:) = dist;
    end
end

end