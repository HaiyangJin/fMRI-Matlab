function ds = rsa_extract(ds, mask, dim, exclude)
% ds = rsa_extract(ds, mask, dim, exclude)
%
% Extract specific RDMs from ds. 
%
% Inputs:
%     ds        <struct> RDM ds. 
%     mask      <boo> boolean to keep the ds.a.conditions. 
%           or  <cell str> cell strings to be compared with the
%                corresponding dimentions, depending on {dim}.
%                when dim is -1, {mask} will be compared to {ds.a.conditions};
%                when dim is 2, {mask} will be comppared to {ds.fa.labels};
%                when dim is 3, {mask} will be compared to {ds.pa.labels};
%     dim       <int> apply the {mask} to which dimension. Default to 0.
%                0 corresponds to extract certain conditions, length of 
%                   {mask} should match that of {ds.a.conditions};
%                2 corresponds to different brain RDMs, length of {mask}
%                   should match {size(ds.samples, 2)};
%                3 corresponds to different labels, , length of {mask}
%                   should match {size(ds.samples, 3)}; 
%                1 corresponds to different values in the vector RDM.
%                   Usually this option should not be used (you may use -1
%                   instead).
%     exclude  <boo> whether to exclude the conditions included in {mask}.
%               Default to 0. 
%
% Output:
%     ds        <struct> extracted ds.
%
% Created by Haiyang Jin (2022-Aug-22)

if nargin < 1
    fprintf('Usage: ds = rsa_extract(ds, mask, dim);\n');
    return
end %nargin

if ~exist('dim', 'var') || isempty(dim)
    dim = 0;
elseif dim == 1
    warning(['{mask} will be applied to Dimention 1. ' ...
        'Please make sure if it is what you want.'])
end %dim

if ~exist('exclude', 'var') || isempty(exclude)
    exclude = 0;
end

% the length of masks
N_masks = [length(ds.a.conditions), size(ds.samples, 1), ...
    size(ds.samples, 2), size(ds.samples, 3)];
if ~exist('mask', 'var') || isempty(mask)
    mask = ones(1,N_masks(dim+1));
elseif ischar(mask) % convert string to cell
    mask = {mask};
elseif size(mask,1)>1 % make mask to a row vector
    mask = mask'; 
end

switch dim

    case 0 % update .a.conditions

        if iscellstr(mask) %#ok<ISCLSTR> 
            mask = ismember(ds.a.conditions, mask);
        else
            mask = logical(mask);
        end

        if exclude
            mask = 1-mask;
        end

        % make sure the length of mask is correct
        nCond = length(ds.a.conditions);
        assert(length(mask)==nCond, ['The length of {mask} (%d) does not match' ...
            ' that of {ds.a.conditions} (%d).'], length(mask), nCond);

        % update .a.conditions
        ds.a.conditions(~mask) = [];

        % update .samples
        tmp_cond = 1:nCond;
        old_p = nchoosek(tmp_cond, 2);
        updated_p = nchoosek(tmp_cond(mask), 2);

        % only keep samples for interested conditions
        ds.samples(~ismember(old_p, updated_p, 'rows'), :, :) = [];

    case 2 % update .fa.labels 

        if iscellstr(mask) %#ok<ISCLSTR> 
            mask = ismember(ds.fa.labels, mask);
        else
            mask = logical(mask);
        end

        if exclude
            mask = 1-mask;
        end

        % make sure the length of mask is correct
        nLabel = size(ds.samples, dim);
        assert(length(mask)==nLabel, ['The length of {mask} (%d) does not match' ...
            ' {size(ds.samples, %d)} (%d).'], length(mask), dim, nLabel);

        % update .fa.labels
        ds.fa.labels(~mask) = [];

        % update .samples
        ds.samples(:, ~mask, :) = [];

    case 3 % update .pa.labels

        if iscellstr(mask) %#ok<ISCLSTR> 
            mask = ismember(ds.pa.labels, mask);
        else
            mask = logical(mask);
        end

        if exclude
            mask = 1-mask;
        end

        % make sure the length of mask is correct
        nSubj = size(ds.samples, dim);
        assert(length(mask)==nSubj, ['The length of {mask} (%d) does not match' ...
            ' {size(ds.samples, %d)} (%d).'], length(mask), dim, nSubj);

        % update .pa.labels
        ds.pa.labels(~mask) = [];

        % update .samples
        ds.samples(:, :, ~mask) = [];

    case 1 % update RDMs {maybe you want to use 0}

        if iscellstr(mask) %#ok<ISCLSTR> 
            error('Please use boolean when {dim} is 1.')
        else
            mask = logical(mask);
        end

        if exclude
            mask = 1-mask;
        end

        % make sure the length of mask is correct
        N = size(ds.samples, dim);
        assert(length(mask)==N(dim), ['The length of {mask} (%d) does not match' ...
            ' {size(ds.samples, %d)} (%d).'], length(mask), dim, N);

        warning('{.a.conditions} has not been updated.')

        % update .samples
        ds.samples(~mask, :, :) = [];


    otherwise
        error('Invalid {dim}.')

end %switch

end %function

