function ds_avg = rsa_avg(ds_rdm, transform, add, dim)
% ds_avg = rsa_avg(ds_rdm, transform, add, dim)
% 
% Get the average across participants.
%
% Inputs:
%     ds_rdm      <struct> RDM ds. 
%     transform   <func handle> function to be used to transform values
%                  before averaging. Default to {identity}.
%     add         <boo> whether only output the average RDM (default) or 
%                  add average RDM before all participants'. Default to 0.
%     dim         <int> get the average along which dimension. Default to 3.
%     
% Output:
%     ds_rdm      <struct> output RDM ds.
%
% Created by Haiyang Jin (2022-Aug-24)

if nargin < 1
    fprintf('Usage: ds_avg = rsa_avg(ds_rdm, transform, add, dim);\n');
    return
end

if ~exist('transform', 'var') || isempty(transform)
    transform = @(x)(x);
end

if ~exist('add', 'var') || isempty(add)
    add = 0;
end

if ~exist('dim', 'var') || isempty(dim)
    dim = 3;
end

% Calculate the average
average = mean(transform(ds_rdm.samples), dim, 'omitnan');

% convert the same correlation for all participants to one cell
sample_cell = num2cell(ds_rdm.samples, dim);
% remove nan
sample_rmnan = cellfun(@(x) rmmissing(x(:)), sample_cell, 'uni', false);
% descriptive 
N = cellfun(@length, sample_rmnan);
sd = cellfun(@std, sample_rmnan);
se = sd./sqrt(N);

% create ds_avg and save .samples
ds_avg = ds_rdm;
ds_avg.pa.labels = {'average', 'se', 'N'};
ds_avg.samples = cat(3, average, se, N);

% output
if add
    % concatenate both ds
    ds_avg = rsa_stack({ds_avg, ds_rdm}, 3);
end

end