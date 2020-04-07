function trgSubj = fs_trgsubj(subjCode, template)
% trgSubj = fs_trgsubj(subjCode, template)
%
% This function output the target subject code based on the template. 
%
% Inputs:
%     subjCode         <string> subject code in SUBJECTS_DIR.
%     template         <string> 'fsaverage' or 'self'. 
%
% Output:
%     trgSubj          <string> the target subject code.
%
% Created by Haiyang Jin (7-Apr-2020)

if ~ismember(template, {'fsaverage', 'self'})
    error('The template has to be ''fsaverage'' or ''self'' (not ''%s'').', template);
end

% decide the trgSubj based on template
switch template
    case 'fsaverage'
        trgSubj = 'fsaverage';
    case 'self'
        trgSubj = subjCode;
end

end