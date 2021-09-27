function boldext = fs_template2boldext(template)
% This function converts the template name to the bold extension. Some 
% templates, which are not often used, are ignored here.
%
% Input:
%     template         the template to be used for projecting functional
%                      data to the structural data (on surface)
% Output:
%     boldext          bold extension 
%
% Created by Haiyang Jin (20-Jan-2020)

if strcmp(template, 'self')   % self surface space
    boldext = ['_' template];
    
elseif length(template) >= 9 && strcmp(template(1:9), 'fsaverage') % fsaverage* space
    
    boldext = '_fsavg';
    temp = regexp(template, '\d', 'once');  % check which fsaverage
    
    if ~isempty(temp)
        tempnum = template(temp);
        
        if ismember(tempnum, {'3', '4', '5', '6'}) % only these fsaverage are available
            boldext = [boldext tempnum];
        else
            error('Cannot find %s in $SUBJECTS_DIR', template);
        end
    end
    
else % error for other templates (including those which are not used often).
        error('The <tempalte> has to be ''self'' or ''fsaverage*''');
end

end