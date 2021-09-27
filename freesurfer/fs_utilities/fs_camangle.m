function fscmd_camera = fs_camangle(contrast, hemi)
% This function generates the camera angle used in FreeView
%
% Inputs:
%    contrast          the contrast name
%    hemi              for which hemisphere
% Output:
%    fscmd_camera      command used for FreeView
%
% Created by Haiyang Jin (11/12/2019)


% the camera angle
isLeft = strcmp(hemi, 'lh');

[conStart, conEnd] = regexp(contrast, '\w*\-vs');

% set camera angle based on contrast
if ~isempty(contrast)
    switch contrast(conStart:(conEnd-3))
        case {'f', 'face', 'w', 'word', 'sce', 'scene' ...
                , 'rep', 'ord', 'rev'}
            angle = 240 + 60 * isLeft;
            fscmd_angle = sprintf('elevation %d', angle);
            
        case {'object', 'o'}
            angle = 180 * ~isLeft;
            fscmd_angle = sprintf('azimuth %d', angle); % camera angle for LOC
            
    end
end

if ~exist('fscmd_angle', 'var'); fscmd_angle = ''; end

fscmd_camera = [' -cam dolly 1.5 ' fscmd_angle];

end