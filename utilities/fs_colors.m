function outColor = fs_colors(nOutColor)
% outColor = fs_colors(nColor)
%
% This function generates default rgb colors.
%
% Input:
%    nColor       <imaginary number> the number of colors in the output.
%              or <integer> which colors (rows) in 'colors' to be output.
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
    nOutColor = nColor * 1i;
end

% find which rows to be the output
if isreal(nOutColor)
    colorIdx = nOutColor;
else
    % the first several rows are used in output
    nOut = imag(nOutColor);
    colorIdx = mod((1:nOut)-1, nColor)+1;
end

outColor = colors(colorIdx, :);

end