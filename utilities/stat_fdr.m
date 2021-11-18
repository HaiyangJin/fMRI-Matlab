function [p_thresh, isSig] = stat_fdr(pvalues, q)
% [p_thresh, isSig] = stat_fdr(pvalues, q)
%
% Correct raw p-values with false discovery rate. 
%
% Inputs:
%    pvalues     <num vec> raw p-values. 
%    q           <num> q in False Discovery Rate. Default is 0.05.
%
% Output:
%    p_thresh    <num> the "threshold" binary significance. It could happen
%                 that some p-values were not significant although they 
%                 were smaller than p_thresh.
%    isSig       <boo vec> whether each raw p-value is significant.
%
% Example: 
% [p_thresh, isSig] = stat_fdr([0.001, 0.05*2/3+0.001, 0.049]);
%
% Created by Haiyang Jin (2021-11-18)

if ~exist('q', 'var') || isempty(q)
    q = 0.05;
end

% sort and the length of p
p_sort = sort(pvalues);
np = length(p_sort);

% whether each p is significant
isSig = p_sort <= (1:np)/np*q;
nSig = sum(isSig);

idx_thresh = find(isSig, 1, 'last');
p_thresh = p_sort(idx_thresh);

if nSig < idx_thresh
    smaller_sig = p_sort(1:idx_thresh);
    nonsig_small = smaller_sig(~isSig(1:idx_thresh)); 
    warning(['Following p-values were not significant although they were ' ...
        'smaller than the threshold (%f): %s'], p_thresh, ...
        sprintf('\n%f', nonsig_small(:)));
end

end