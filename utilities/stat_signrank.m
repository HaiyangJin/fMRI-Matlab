function [p,h,stat] = stat_signrank(x, y, varargin)
% [p,h,stat] = stat_signrank(x, y, varargin)
%
% Wrapper for signrank (Matlab function). When y is empty, one-sided signed
% rank test will perform by default (alternative hypothesis: median > 0).
%
% Inputs:
%    x,y        <vec> the input vectors.
%    varargin   options in signrank (matlab function).
%
% Output:
%    p          <num> p-value.
%    h          <boo> whether the null hypothesis was rejected. 
%    stats      <num> stats results.
% 
% Created by Haiyang Jin (2021-11-18)

tail = 'both';
if ~exist('y', 'var') || isempty(y)
    y = [];
    if ~ismember('tail', varargin)
        tail = 'right';
        warning('One-sided Wilcoxon signed rank test (median>0) was performed by default.');
    end
end

opts = horzcat({'tail',tail, 'alpha',0.05, 'method','exact'}, varargin);
[p,h,stat] = signrank(x,y,opts{:});

end
