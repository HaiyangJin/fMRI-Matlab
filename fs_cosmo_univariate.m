function ds_table = fs_cosmo_univariate(ds)
% This function convert the ds of CoSMoMVPA to a table for univariate
% analysis
%
% Created by Haiyang Jin (18/11/2019)

ds_table = table;

ds_table.Resp = mean(ds.samples, 2);
ds_table.Conditions = ds.sa.labels;
ds_table.Target = ds.sa.targets;

end