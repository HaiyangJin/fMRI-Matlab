function fv_checkrecon(subjCode, subjPath)
% fv_checkrecon(subjCode, subjPath)
%
% This function plots the T1.mgz, brainmask.mgz, ?h.white and ?h.pial in
% Freeview for checking the results of recon-all in FreeSurfer.
%
% Inputs:
%     subjCode         <string> subject code in $SUBJECTS_DIR.
%     subjPath         <string> $SUBJECTS_DIR
%
% Output:
%     open freeview to display the volumes and surfaces.
%
% Created by Haiyang Jin (29-March-2020)

% use SUBJECTS_DIR as the default if necessary
if nargin < 2 || isempty(subjPath)
    subjPath = getenv('SUBJECTS_DIR');
end

% create the commands
fscmd = sprintf(['freeview -v %1$s/mri/brainmask.mgz ' ...
    '%1$s/mri/wm.mgz:colormap=heat:opacity=0.4 '...
    '-f %1$s/surf/lh.white:edgecolor=yellow '...
    '%1$s/surf/lh.pial:edgecolor=red '...
    '%1$s/surf/rh.white:edgecolor=yellow '...
    '%1$s/surf/rh.pial:edgecolor=red &'], ...
    fullfile(subjPath, subjCode));

% run the commands
system(fscmd);

end