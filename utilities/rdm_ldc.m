function rdm = rdm_ldc(mat_hyper, mat_test, residual1)
% rdm = rdm_ldc(mat_hyper, mat_test, residual1)
%
% This function computes Linear Discriminant Contrast distance for the
% input matrices. mat_hyper is used to make the hyperplane and mat_test is
% used to test the pairwise distance.
%
% Inputs:
%    mat_hyper  <num mat> P x Q; each row is one stimulus/condition and
%                each column is one feature (e.g., voxel or vertex). mat1
%                will be used to make the hyperplane.
%    mat_test   <num array> P x Q x R; the first and second dimensions are
%                stimulus/condition and feature. The third dimension is
%                used if multiple test datasets are applicable.
%    residual1  <num mat> P X Q. (What is P? number of volume/TR?)
%
% Output:
%    rdm        <num array> P x P; each row and each column is one
%                stimulus/condition.
%
% See also:
% ldc_dist

assert(ismatrix(mat_hyper), 'mat_hyper has to be 2-dimension.');

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
        dist = ldc_dist(vec_hyper, vec_test, residual1);

        rdm(cond1,cond2,:) = dist;
    end
end

end