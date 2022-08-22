function ds = rdm_rmcond(ds, mask)
% ds = rdm_rmcond(ds, mask)
%
% Remove certain conditions from ds. 
%
% Inputs:
%     ds        <struct> RDM ds. 
%     mask      <boo> boolean to keep the ds.a.conditions. 
%
% Output:
%     ds        <struct> filtered ds.
%
% Created by Haiyang Jin (2022-Aug-22)

if nargin < 1
    fprintf('Usage: ds = rdm_rmcond(ds, mask);\n');
end

nCond = length(ds.a.conditions);

if ~exist('mask', 'var') || isempty(mask)
    mask = ones(1,nCond);
elseif size(mask,1)>1
    % make mask to a row vector
    mask = mask';
end
mask = logical(mask);
assert(length(mask)==nCond, ['The length of {mask} (%d) does not match' ...
    ' that of conditions in {ds} (%d).'], length(mask), nCond);

% update the .a.conditions
ds.a.conditions(~mask) = [];

% update the .samples
tmp_cond = 1:nCond;
old_p = nchoosek(tmp_cond, 2);
updated_p = nchoosek(tmp_cond(mask), 2);

% only keep samples for interested conditions
ds.samples(~ismember(old_p, updated_p, 'rows'), :) = [];  

end

