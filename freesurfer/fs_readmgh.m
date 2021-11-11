function hdr = fs_readmgh(fname,slices,frames,headeronly)
% hdr = fs_readmgh(fname,slices,frames,headeronly)
%
% All the inputs are the same as those for load_mgh. The only difference is
% that the output is saved as a struct.
%
% Created by Haiyang Jin (2021-10-12)
%
% See also:
% fm_readimg; load_mgh

if ~exist('slices', 'var') || isempty(slices)
    slices = [];
end
if ~exist('frames', 'var') || isempty(frames)
    frames = [];
end
if ~exist('headeronly', 'var') || isempty(headeronly)
    headeronly = 0;
end

[vol, M, mr_parms, volsz] = load_mgh(fm_cleancmd(fname),slices,frames,headeronly);

hdr.vol = vol;
hdr.M = M;
hdr.mr_parms = mr_parms;
hdr.volsz = volsz;

end
