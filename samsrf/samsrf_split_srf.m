function [SrfCell, SrfFnList] = samsrf_split_srf(Srf, condIdx, condNames)
% SrfCell = samsrf_split_srf(Srf, condIdx, condNames)
%
% Split the Srf file into multiple Srf files for each condition in condIdx.
% The output file will be saved in the current working directory if `Srf` 
% is a struct, or save as the same folder as `Srf` if it is a string.
%
% Inputs:
%    Srf         <struct> A SamSrf surface data files (e.g., created by
%                 samsrf_gii2srf()).
%             OR <str> path to the Srf file.
%    condIdx     <int vec> A list of condition indices. It has to be the
%                 same size as size(Srf.Data,2). 0 will not be saved in any
%                 Srf file. Srf corresponding to other integers will be 
%                 saved as a separated Srf file.
%    condNames   <str cell> names for the split Srf files. Default to
%                 'Cond' plus the condition index. For example, if the
%                 `condIdx` is [0, 1, 3], `condNames` will be {'Cond1',
%                 'Cond3'} (0 will not be saved). 
%
% Output:
%    SrfCell     <cell> splitted Srf struct. 
%    SrfFnList   <cell str> A list of the output file names.
%
% 26/06/2023 - Written (HJ)

%% Deal with inputs
idxlist = unique(condIdx);
idxlist(idxlist==0) = [];
Nidx = length(idxlist);

if ~exist('condNames', 'var') || isempty(condNames)
    condNames = arrayfun(@(x) sprintf('Cond%d', x), idxlist, 'uni', false);
end

% load 
outpath = '';
if ischar(Srf)
    [outpath, outfile] = fileparts(Srf);
    load(EnsurePath(Srf), 'Srf');
else
    outfile = sprintf('%s_func', Srf.Hemisphere);
end
if isempty(outpath); outpath = pwd; end

assert(size(Srf.Data, 1)==length(condIdx), ['The length of condIdx (%d) ' ...
    ' has to match the timepoints in Srf.Data (%d).'], ...
    length(condIdx), size(Srf.Data, 2));
origSrf = Srf;

%% Split Srf
SrfCell = cell(Nidx,1);
SrfFnList = cell(Nidx,1);
for idx = 1:Nidx
    % only keep matched volumes
    Srf = origSrf;
    Srf.Data = Srf.Data(condIdx == idx,:);
    Srf.Values = Srf.Values(condIdx == idx);

    % save the split 
    thisFile = fullfile(outpath, sprintf('%s_%s', outfile, condNames{idx}));
    save(thisFile, 'Srf', '-v7.3');
    fprintf('[%d/%d] Saved split Srf %s\n', idx, Nidx, thisFile);
    SrfFnList{idx,1} = thisFile;
end

end