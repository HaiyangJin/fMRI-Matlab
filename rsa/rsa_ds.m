function ds_rdm = rsa_ds(samples, varargin)
% ds_rdm = rsa_ds(samples, varargin)
%
% Create a new RDM (e.g., model RDM).
%
% Inputs:
%     samples     <mat> matrix of samples; each column is one RDM and the
%                  third dimenstion is for participants.
%
% Varargin:
%     .condlist   <cell str> condition names whose order should match the
%                  pairs in .samples (each column).
%     .labellist  <cell str> labels for each column in .samples.
%     .subjlist   <cell str> subject list for the third dimension in
%                  .samples.
%
% Output:
%     ds_rdm      <struct> output RDM ds.
%
% Created by Haiyang Jin (2022-Aug-24)

if nargin < 1
    fprintf('Usage: rsa_ds = rsa_ds(samples, varargin);\n');
    return
end

defaultOpts = struct( ...
    'condlist', '', ...
    'labellist', '', ...
    'subjlist', '');
opts = fm_mergestruct(defaultOpts, varargin);

% create a new struct
ds_rdm = struct();
ds_rdm.samples = samples;

%% Add the fields if needed
if ~isempty(opts.condlist)
    assert(nchoosek(length(opts.condlist),2)==size(samples,1), ['The length' ...
        ' of {.condlist} does not seem to match what it should be for {size(samples,1)}.'])
    % make it to (column) vector
    if size(opts.condlist, 1) == 1
        opts.condlist = opts.condlist';
    end
    ds_rdm.a.conditions = opts.condlist;
end

if ~isempty(opts.labellist)
    assert(length(opts.labellist)==size(samples, 2), ['The length of ' ...
        '{.labellist} does not seem to match {size(samples,2)}']);
    % make it to row vector
    if size(opts.labellist, 2) == 1
        opts.labellist = opts.labellist';
    end
    ds_rdm.fa.labels = opts.labellist;
end

if ~isempty(opts.subjlist)
    assert(length(opts.subjlist)==size(samples, 3), ['The length of ' ...
        '{.subjlist} does not seem to match {size(samples,3)}.']);
    % make it to (column) vector
    if size(opts.subjlist, 1) == 1
        opts.subjlist = opts.subjlist';
    end
    ds_rdm.pa.labels = opts.subjlist;
end

end