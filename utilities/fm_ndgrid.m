function varargout = fm_ndgrid(varargin)
% varargout = fm_ndgrid(varargin)
%
% Similar to ndgrid but the output will be in one column.
%
% Inputs:
%    varargin   <same as ndgrid>
%
% Outputs:
%    varargout  <similar to ndgrid but in columns>
%
% % Example 1:
% [tmp1, tmp2] = fm_ndgrid({'test1', 'test2'}, {'test3', 'test4'});
%
% Example 2:
% [tmp1, tmp2] = fm_ndgrid({'test1', 'test2'}, 2);
%
% Created by Haiyang Jin (2021-10-28)

% convert to cell if it is not
iscells = cellfun(@iscell, varargin);
varargin(~iscells) = cellfun(@(x) {x}, varargin(~iscells), 'uni', false);

% get the output from ndgrid
out = cell(1,max(nargout,1));
[out{:}] = ndgrid(varargin{:});

% make the output in columns
varargout = cellfun(@(x) x(:), out, 'uni', false);

end