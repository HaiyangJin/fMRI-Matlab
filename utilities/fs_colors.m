function outColor = fs_colors(nOutColor)
% outColor = fs_colors(nColor)
%
% This function generates the default colors.
% 
% Input: 
%    nColor       <integer> the number of colors want in the output.
%
% Output:
%    outColor     <numeric array> nColor x 3. 
%
% colors = [
%     1, 1, 1;  % white
%     1, 1, 0;  % yellow
%     1, 0, 1;  % Magenta / Fuchsia
%     0, 1, 0;  % green
%     .5, 0, 1;  % purple
%     0, 1, 1;  % blue
%     0, 0, 0;  % black
%     ];
%
% Created by Haiyang Jin (28-Apr-2020)

colors = [
    1, 1, 1;  % white
    1, 1, 0;  % yellow
    1, 0, 1;  % Magenta / Fuchsia
    0, 1, 0;  % green
    .5, 0, 1;  % purple
    0, 1, 1;  % blue
    0, 0, 0;  % black
    ];
nColor = size(colors, 1);

if ~exist('nOutColor', 'var') || isempty(nOutColor)
    nOutColor = nColor;
end

colorIdx = mod((1:nOutColor)-1, nColor)+1;

outColor = colors(colorIdx, :);

end