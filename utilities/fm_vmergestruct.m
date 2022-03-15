function outS = fm_vmergestruct(varargin)
% outS = fm_vmergestruct(varargin)
%
% Merge struct vertically and assign empty string to missing fieldnames.
%
% Input:
%    varargin    multiple struct to be merged.
%
% Output:
%    outS       <struct> the merged struct.
%
% Created by Haiyang Jin (2022-March-03)

fnC = cellfun(@(x) fieldnames(x), varargin, 'uni', false);
fns = unique(vertcat(fnC{:}));
for ifn = 1:length(fns)
    for ib = 1:length(varargin)
        if ~isfield(varargin{ib}, fns{ifn})
            varargin{ib}.(fns{ifn})='';
        end
    end
end
outS = vertcat(varargin{:});

end