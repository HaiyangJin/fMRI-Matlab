function sig = fm_2sig(fnList)
% sig = fm_2sig(fnList)
%
% This function identify the significance p-value from the filename.
%
% Input:
%    fnList        <cell string> a list of filenames.
% 
% Output:
%    sig           <numeric> the p-value in FreeSurfer.
%
% Created by Haiyang Jin (20-Apr-2020)

if ischar(fnList); fnList = {fnList}; end 

% find strings match f\d+ pattern
sigCell = cellfun(@(x) regexp(x, 'f\d+', 'match'), fnList, 'uni', false);

% remove the 'f'
sigNum = cellfun(@(x) str2double(erase(x, 'f')), sigCell, 'uni', false); 

% convert to numeric if possible
if numel(sigNum) == 1
    sig = sigNum{1};
else
    sig = sigNum;
end

end