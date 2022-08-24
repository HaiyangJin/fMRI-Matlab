function ds_cmp = rdm_compare(ds_brain, ds_model, type)
% ds_cmp = rdm_compare(ds_brain, ds_model, type)
%
% Compare brain RDM and model RDMs. 
%
% Inputs:
%     ds_brain    <struct> brain RDMs. Each column in .samples is one brain
%                  RDM (vector). The third dimension is the participant.
%     ds_model    <struct> model RDMs. Eech column in .samples is one model
%                  RDM (vector). Default to the first RDM in
%                  ds_brain.samples.
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
    fprintf('Usage: ds_cmp = rdm_compare(ds_brain, ds_model, type);\n');
    return
end %nargin

convert = 0;
if ~exist('ds_model', 'var') || isempty(ds_model)
    % default to the first RDM in 
    ds_model = ds_brain;
    ds_model.samples = ds_brain.samples(:,:,1);
    ds_model.pa = [];
    ds_model.a.conditions = [ds_brain.fa.labels, ds_model.fa.labels];
    ds_brain.a.conditions = [ds_brain.fa.labels, ds_model.fa.labels];
    convert = 1;
end

% make sure both ds have the same .a.conditions
assert(isequal(ds_brain.a.conditions, ds_model.a.conditions), ['The ' ...
    '{.a.conditions} in {ds_brain} and {ds_model} does not match.'])

% make sure there are only two dimentions in ds_model.samples
assert(ndims(ds_model.samples)<=2, ['{ds_models.samples} should only ' ...
    'have two dimensions (not %d).'], ndims(ds_model.samples));

if ~exist('type', 'var') || isempty(type)
    type = 'kendall_taua';
elseif strcmp(type, 'Pearson') % throw warnings for some methods
    warning('Pearson (instead of rank correlation) is used to compare models.');
elseif strcmp(type, 'Kendall')
    warning('Kendall tau b (instead of tau a) is used to compare models.');
end

%% Compare RDMs

N_models = size(ds_model.samples, 2);

% create empty array to save output
out = NaN(N_models, size(ds_brain.samples, 2), ...
    size(ds_brain.samples, 3));

% comapre model for each participant separately
for iSubj = 1:size(ds_brain.samples, 3)

    % create ds for this subj
    ds_subj = ds_brain;
    ds_subj.samples = ds_brain.samples(:,:,iSubj);

    % compare models for each subject separately
    out(:,:,iSubj) = compare_separate(ds_subj, ds_model, type);

end %iSubj

% make a copy of ds_brain (mainly use the .fa, .a, and .pa)
ds_cmp = ds_brain;

if convert
    % convert matrix to vec
    out = rdm_rdm2vec(out);

    ds_cmp.fa.labels = {'Representational Similarity Matrix'};

else
    % obtain the .sa
    ds_cmp.sa.model = ds_model.fa.labels';
    ds_cmp.sa.type = repmat({type}, N_models, 1);
    ds_cmp.sa.metric = repmat({'correlation'}, N_models, 1);
    ds_cmp.sa.labels = repmat({'rho'}, N_models, 1);

    % update "condition" names
    ds_cmp.a.conditions = ds_model.fa.labels;
end

% save the rho
ds_cmp.samples = out;

end %function


function outcorr = compare_separate(ds_brain, ds_model, type)

N_models = size(ds_model.samples, 2);

% use different method to compare models
switch type

    case 'kendall_taua'
        
        [tmp_model, tmp_brain] = ndgrid(1:N_models, 1:size(ds_brain.samples, 2));
        out = arrayfun(@(x,y) rsa.stat.rankCorr_Kendall_taua( ...
            ds_model.samples(:,x), ds_brain.samples(:,y)), ...
            tmp_model(:), tmp_brain(:));

        outcorr = reshape(out, N_models, size(ds_brain.samples, 2));

    case {'Kendall', 'Spearman', 'Pearson'}

        outcorr = corr(ds_model.samples, ds_brain.samples, 'type', type);

    otherwise
        error('Cannot identify the correaltion type (%s).', type);

end %switch type

end %compare_one_subj()