function ds_out = rdm_stack(ds_cell, dim)
% ds_out = rdm_stack(ds_cell, dim)
%
% Concatenate RDM ds along dim (2 or 3).
%
% Inputs:
%     ds_cell      <cell> a group of ds.
%     dim          <int> Along which dimension to concatenate RDMs. Default
%                   to 2: concatenate multiple RDM (e.g., brain and model
%                   RDM) and compare them (e.g., use rdm_compare()). 
%                   3: concatenate mulplte RDMs from different
%                   participants. 
%
% Output:
%     ds_out       <struct> output ds.
%
% Created by Haiyang Jin.
%
% See also:
% rdm_compare

if nargin < 1
    fprintf('Usage: ds_out = rdm_stack(ds_cell, dim);\n');
    return
end

% copy properties form the first ds_rdm
ds_out = ds_cell{1};

% concatenate samples
samples = cellfun(@(x) x.samples, ds_cell, 'uni', false);
ds_out.samples = cat(dim, samples{:});

switch dim

    case 2
        % concatenate multiple RDMs (and compare them)
        fa_labels = cellfun(@(x) x.fa.labels, ds_cell, 'uni', false);
        ds_out.fa.labels = cat(2, fa_labels{:});

    case 3
        % concatenate multiple RDMs from different participants
        pa_labels = cellfun(@(x) x.pa.labels, ds_cell, 'uni', false);
        ds_out.pa.labels = cat(2, pa_labels{:});

end %swtich

end