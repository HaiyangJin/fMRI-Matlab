function ds_avg = rdm_avg(ds_rdm, transform, add, dim)
% ds_avg = rdm_avg(ds_rdm, transform, add, dim)
% 
% Get the average across participants.
%
% Inputs:
%     ds_rdm      <struct> RDM ds. 
%     transform   <func handle> function to be used to transform values
%                  before averaging. Default to {identity}.
%     add         <boo> whether only output the average RDM (default) or 
%                  add average RDM before all participants'.  
%     dim         <int> get the average along which dimension.
%     
% Output:
%     ds_rdm      <struct> output RDM ds.
%
% Created by Haiyang Jin (2022-Aug-24)

if nargin < 1
    fprintf('Usage: ds_avg = rdm_avg(ds_rdm, transform, add, dim);\n');
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
ds_avg = ds_rdm;
ds_avg.pa.labels = {'average'};
ds_avg.samples = mean(transform(ds_rdm.samples), dim, 'omitnan');

% output
if add
    % concatenate both ds
    ds_avg = rdm_stack({ds_avg, ds_rdm}, 3);
end

end