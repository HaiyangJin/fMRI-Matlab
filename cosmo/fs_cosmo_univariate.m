function dsTable = fs_cosmo_univariate(ds)
% This function convert the ds of CoSMoMVPA to a table for univariate
% analysis
%
% Created by Haiyang Jin (18/11/2019)

dsTable = table;

dsTable.Resp = mean(ds.samples, 2);
dsTable.Conditions = ds.sa.labels;
dsTable.Target = ds.sa.targets;

end