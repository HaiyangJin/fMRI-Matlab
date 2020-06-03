function fthresh = fs_2thresh(filename, toNumeric)
% fthresh = fs_2thresh(filename)
%
% This function identify the fthreshold.
%
% Inputs:
%    filename        <string> the file name.
%    toNumeric       <logical> 1 [default]: convert the threshold to
%                     numeric.
%
% Output:
%    fthresh         <string> the f threshold, e.g., f13.
%
% Created by Haiyang Jin (3-Jun-2020)

% identify 'f*'
thresh = regexp(filename, '\.f\d*\.', 'match');

if toNumeric
    fthresh = thresh{1}(2:end-1);
else
    fthresh = thresh;
end

end