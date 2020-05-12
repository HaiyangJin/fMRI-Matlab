function viewpt = fs_cvn_viewpt(viewIdx, isHemi)
% viewpt = fs_cvn_viewpt(viewIdx, isHemi)
%
% This function generates the viewpt matrix for fs_cvn_lookup.m.
%
% Inputs:
%    viewIdx        <string> the name of this viewIdx.
%    isHemi         <logical vector> 1x2 vector. The first and second
%                    values shows whether left and right hemisphere will be
%                    shown respectively.
%
% Output:
%    viewpt         <cell> cell of viewpoint vectors for fs_cvn_lookup.m.
%
% Created by Haiyang Jin (12-May-2020)

% find the vectors for both hemispheres
switch viewIdx
    case {'ffa', 'ventral', 'f-vs-o', 'face-vs-object'}
        bothViewpt = {[270, -89, 0], [90, -89, 0]};
end

% only keep the hemispheres needed
viewpt = {bothViewpt(isHemi)};

end