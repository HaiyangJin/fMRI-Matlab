function ds_out = cosmo_labelds(ds_in, labelPairs, target0)
% ds_out = cosmo_labelds(ds_in, labelPairs, target0)
%
% Re-labels the labels in CoSMo data set. 
%
% Inputs:
%    ds             <struct> CoSMoMVPA dataset
%    labelPairs     <cell> Px2 cell. The first column is the new label
%                    names and the second column is the labels (a cell str)
%                    to be replaced. Each row is one pair.
%    target0        <int> initial target code (number) for the new labels. 
%                    Default is maximum target number in ds_in.
%
% Outputs:
%    ds             <struct> CoSMoMVPA dataset with updated labels and
%                    targets.
%
% Created by Haiyang Jin (2022-Jan-28)

assert(size(labelPairs,2)==2, 'There should be two columns in labelPairs.');

if ~exist('target0', 'var') || isempty(target0)
    target0 = max(ds_in.sa.targets);
end

ds_out = ds_in;

% re-label each row in .samples
for i = 1:size(labelPairs, 1)
    
    toLabel = ismember(ds_in.sa.labels, labelPairs{i,2});
    
    ds_out.sa.labels(toLabel) = labelPairs(i,1);
    ds_out.sa.targets(toLabel) = target0 + i;

end

end