function anaList = fs_analist(thedir, wcstr)
% anaList = fs_analist(thedir, wcstr)
%
% Gathers all the analysis in the $FUNCTIONALS_DIR.
%
% Input:
%    path       <str> the directory to be inspected.
%    wcstr      <str> wildcard strings to identify analyses.
%
% Output:
%    anaList    <cell str> a list of analyses in FreeSurfer.
%
% Created by Haiyang Jin (2022-02-21)

if ~exist('thedir', 'var') || isempty(thedir)
    thedir = getenv('FUNCTIONALS_DIR');
end

assert(exist(thedir, 'dir'));

if ~exist('wcstr', 'var') || isempty(wcstr)
    wcstr = 'type-ana*';
end

anadir = dir(fullfile(thedir, wcstr));

anaList = {anadir.name}';

end