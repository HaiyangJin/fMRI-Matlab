function template = hcp_template(template)
% template = hcp_template(template)
%
% This function obtains the directory to the specific structure template.
%
% Inputs:
%    template         <str> path starting within the subject folder and
%                      ending where the *.wb.spec file is. E.g.,
%                      'T1w/fsaverage_LR32k'.
%                  OR <int> 1 -> 'T1w/fsaverage_LR32k' (default1);
%                           2 -> 'MNINonLinear/fsaverage_LR32k';
%                           3 -> 'T1w/Native' (default1);
%                           4 -> 'MNINonLinear/Native';
%                           5 -> 'MNINonLinear'.
%
% Output:
%    template          <str> the template.
%
% Created by Haiyang Jin (2021-10-18)

% all five templates
templates = {['T1w' filesep 'fsaverage_LR32k'];
    ['MNINonLinear' filesep 'fsaverage_LR32k'];
    ['T1w' filesep 'Native'];
    ['MNINonLinear' filesep 'Native'];
    'MNINonLinear'};

if ~exist('template', 'var') || isempty(template)
    template = 1;
end
if isint(template)
    template = templates{template};
end

end