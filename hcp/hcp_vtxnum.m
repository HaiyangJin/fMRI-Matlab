function num = hcp_vtxnum(template)
% num = hcp_vtxnum(template)
%
% Return the number of vertices for the template.
%
% Input:
%    template       <str> the template name; can be '164k' or '32k' (default).
%
% Output:
%    num            <num> number of vertices.
%
% Created by Haiyang Jin (2021-09-30)

if ~exist('template', 'var') || isempty(template)
    template = '32k';
end

% available templates
% templates = {'164k', '32k'};

switch template
    case {'164k', '164', 'high'} % high resolution; fsaverage
        num = 163842;
    case {'32k', '32', 'low'} % low resolution
        num = 32492;
    otherwise
        error('Unknown template: %s ', template);
end

end