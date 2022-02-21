function ds = fs_cosmo_sessdsmulti(sessList, anaList, varargin)
% ds = fs_cosmo_sessdsmulti(sessList, anaList, varargin)
%
% Use fs_cosmo_sessds() to read and stack data for multiple sessions. 
% Typically, sessList should inlcude sessions for the same participant
% and anaList should include analyses for the same hemisphere. At least, 
% the output data should have the same number of vertices (and they have the
% same meanings, i.e., same coordinates). Otherwise, even the data can be 
% stacked but they may not make sense [never mind if this description does 
% not make sense :)].
%
% Inputs:
%    sessList     <cell str> a list of session codes. They should refer to
%                  the same participant (or different participants but 
%                  using the same template, e.g., 'fsaverage'). 
%    anaList      <cell str> a list of analysis in FreeSurfer. They should
%                  refer to the same hemisphere. (It may be for both
%                  hemispheres if sessList are participants using the same
%                  template, e.g., 'fsaverage'; not recommended).
%
% Varargin     
%    .across      <boo> whether all analyses are available in all sessions,
%                  default is 1. Otherwise, one session only corresponds to
%                  one analysis in order. 
%    For other options see varargin in fs_cosmo_sessds().
%    .contrast    <str> to read the data within the contrast folder.
%    .datafn      <str> the file to be read.
%
% Output:
%    ds           <struct> (cosmo) dataset struct (with "redundant" sample
%                  attributes of session, analysis, and label filename).
%
% Created by Haiyang Jin (2022-Jan-06)
%
% See also:
% fs_cosmo_sessds

if nargin < 2
    fprintf('Usage: ds = fs_cosmo_sessdsmulti(sessList, anaList, varargin);\n');
    return;
end

if ischar(sessList); sessList = {sessList}; end
subjList = fs_subjcode(sessList, 1);
assert(numel(unique(subjList))==1, ['It seems that the multiple sessions do ' ...
    'not correspond to the same subject.'])

if ischar(anaList); anaList = {anaList}; end
[~, nHemi] = fm_hemi_multi(anaList);
assert(nHemi==1, 'Please make sure the multiple analyses are for the same hemisphere.')

defaultOpts = struct('across', 1);
opts = fm_mergestruct(defaultOpts, varargin{:});

if opts.across
    % across sessions and analyses
    [tmpSess, tmpAna] = ndgrid(sessList, anaList);
else
    % one session correspond to one analysis
    tmpSess = sessList;
    tmpAna = anaList;
end
allSess = tmpSess(:);
allAna = tmpAna(:);

% Processing for each pair
N = length(allSess);
ds_cell = cell(N, 1);

for i = 1:N

    % read data for each pair
    [tmp_ds, dsInfo] = fs_cosmo_sessds(allSess{i}, allAna{i}, opts);

    % add "redundant" information
    tmp_ds.sa.sessions = repmat(dsInfo.SessCode, size(tmp_ds.sa.targets, 1), 1);
    tmp_ds.sa.analysis = repmat(dsInfo.Analysis, size(tmp_ds.sa.targets, 1), 1);
    tmp_ds.sa.labelfn = repmat(dsInfo.Label, size(tmp_ds.sa.targets, 1), 1);

    ds_cell{i} = tmp_ds;

end

% stack all ds
ds = cosmo_stack(ds_cell, 1);

end