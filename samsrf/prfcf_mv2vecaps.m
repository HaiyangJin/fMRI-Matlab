function prfcf_mv2vecaps(mvaps_wc, scaling_factor)
% mvap_wc    <str> wildcard to identify movie apetures.

% identify move aperture files
mvaplist = dir(mvaps_wc);
assert(~isempty(mvaplist), 'Cannot find any matched movie apetures.');

% only keep file names
[~, fnames] = cellfun(@fileparts, {mvaplist.name}, 'uni', false);

% convert to vectorised apertures
cellfun(@(x) VectoriseApertures(x, scaling_factor), ...
    fullfile({mvaplist.folder}, fnames), 'uni', false);

end
