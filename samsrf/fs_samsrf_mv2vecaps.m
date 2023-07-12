function fs_samsrf_mv2vecaps(mvaps_wc, scaling_factor)
% fs_samsrf_mv2vecaps(mvaps_wc, scaling_factor)
%
% Convert the movie apertures to vectorized apertures and save the output
% files in the current working directory.
%
% Inputs:
%     mvap_wc                <str> wildcard to identify movie apetures.
%     scaling_factor         <num> the maximum of eccentricity.
%
% Created by Haiyang Jin (2023-June-1)

% identify move aperture files
mvaplist = dir(mvaps_wc);
assert(~isempty(mvaplist), 'Cannot find any matched movie apetures.');

% only keep file names
[~, fnames] = cellfun(@fileparts, {mvaplist.name}, 'uni', false);

% convert to vectorised apertures
cellfun(@(x) VectoriseApertures(x, scaling_factor), ...
    fullfile({mvaplist.folder}, fnames), 'uni', false);

end
