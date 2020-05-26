function uniTable = fs_ds2uni(ds, condInfo)
% uniTable = fs_ds2uni(ds, condInfo)
%
% This function convert the ds from CoSMoMVPA to a table for univariate
% analysis. 
% This function will be deprecated later. You may want to use
% fs_cosmo_readata.m instead.
%
% Inputs:
%     ds                <structure> data set obtained from CoSMoMVPA.
%     condInfo          <structure> condition information.
%
% Output:
%    uniTable           <table> data table for univariate analysis.
%
% Created by Haiyang Jin (18-Nov-2019)

%% Convert dataset structure to table
dsTable = table;

dsTable.Resp = mean(ds.samples, 2);
dsTable.Conditions = ds.sa.labels;
dsTable.Target = ds.sa.targets;

%% Add condition information if avaiable
if ~isempty(condInfo)
    % add condiInfo if it is available
    nRowUni = size(ds.samples, 1);
    uniTable = [repmat(condInfo, nRowUni, 1), dsTable];
    
else
    % do not use condition information
    uniTable = dsTable;
end

end