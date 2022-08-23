function ds_cmp = dsm_compare(ds_brain, ds_model, type)
% ds_cmp = dsm_compare(ds_brain, ds_model, type)
%
% Compare brain RDM and model RDMs. 
%
% Inputs:
%     ds_brain    <struct> brain RDMs. Each column in .samples is one brain
%                  RDM (vector).
%     ds_model    <struct> model RDMs. Eech column in .samples is one model
%                  RDM (vector).
%     type        <str> correlation to be used to compare RDMs. Default to
%                  'kendall_taua' (from rsatoolbox). Other options are
%                  methods avaiable in corr in matlab (statistics toolbox).
%
% Output
%     ds_cmp      <struct> comparison results. Each column in .samples is
%                  one brain RDM and each row is one model RDM. 
%
% Created by Haiyang Jin (2022-Aug-23)

if nargin < 1
    fprintf('Usage: ds_cmp = dsm_compare(ds_brain, ds_model, type);\n');
    return
end %nargin

% make sure both ds have the same .a.conditions
assert(isequal(ds_brain.a.conditions, ds_model.a.conditions), ['The ' ...
    '{.a.conditions} in {ds_brain} and {ds_model} does not match.'])

if ~exist('type', 'var') || isempty(type)
    type = 'kendall_taua';
end

%% Compare RDMs
N_models = length(ds_model.fa.labels);

switch type
    case 'kendall_taua'
        
        [tmp_model, tmp_brain] = ndgrid(1:N_models, 1:size(ds_brain.samples, 2));
        out = arrayfun(@(x,y) rsa.stat.rankCorr_Kendall_taua( ...
            ds_model.samples(:,x), ds_brain.samples(:,y)), ...
            tmp_model(:), tmp_brain(:));

        out = reshape(out, N_models, size(ds_brain.samples, 2));

    case {'Kendall', 'Spearman', 'Pearson'}

        out = corr(ds_model.samples, ds_brain.samples, 'type', type);

    otherwise
        error('Cannot identify the correaltion type (%s).', type);

end %switch type

% throw warnings for some methods
if strcmp(type, 'Pearson')
    warning('Pearson (instead of rank correlation) is used to compare models.');
elseif strcmp(type, 'Kendall')
    warning('Kendall tau b (instead of tau a) is used to compare models.');
end

% make a copy of ds_brain (mainly use the .fa and .a)
ds_cmp = ds_brain;

% obtain the .sa
ds_cmp.sa.model = ds_model.fa.labels';
ds_cmp.sa.type = repmat({type}, N_models, 1);
ds_cmp.sa.metric = repmat({'correlation'}, N_models, 1);
ds_cmp.sa.labels = repmat({'rho'}, N_models, 1);

% save the rho
ds_cmp.samples = out;

end %function