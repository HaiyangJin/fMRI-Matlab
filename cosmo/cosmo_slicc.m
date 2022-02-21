function ds_icc = cosmo_slicc(ds, opts)
% ds_icc = cosmo_slicc(ds, opts)
%
% builds the connections between ICC and CoSMoMVPA.
%
% Created by Haiyang Jin (2022-02-20)

[r, LB, UB, F, df1, df2, p] = stat_icc(ds.samples', opts.type, opts.alpha, opts.r0);

% create a new struct to save the output
themask = zeros(size(ds.samples,1),1);
themask(1) = 1;
ds_tmp = cosmo_slice(ds, logical(themask));

ds_icc = struct;
ds_icc.a = ds_tmp.a;

ds_icc.fa.node_indices = ds_tmp.fa.node_indices(1);

ds_icc.samples = [r, LB, UB, F, df1, df2, p]';
ds_icc.sa.labels = {'r', 'LB', 'UB', 'F', 'df1', 'df2', 'p'}';

ds_icc.sa.conditions = repmat(ds_tmp.sa.labels, size(ds_icc.samples,1), 1);
ds_icc.sa.type = repmat(opts.type, size(ds_icc.samples,1), 1);
ds_icc.sa.alpha = repmat(opts.alpha, size(ds_icc.samples,1), 1);
ds_icc.sa.r0 = repmat(opts.r0, size(ds_icc.samples,1), 1);

end