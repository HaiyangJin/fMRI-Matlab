function fv_checkrecon(subjCode, showT1)
% fv_checkrecon(subjCode, subjPath)
%
% This function plots the T1.mgz, brainmask.mgz, ?h.white and ?h.pial in
% Freeview for checking the results of recon-all in FreeSurfer.
%
% Inputs:
%     subjCode         <string> subject code in $SUBJECTS_DIR or full path  
%                       to this subject code folder. [Tip: if you want to
%                       inspect the subject in the current working
%                       directory, run fv_checkrecon('./subjCode').
%     showT1           <logical> 1: show T1.mgz; 0: do not show T1.mgz. By
%                       default: 0.
%
% Output:
%     open freeview to display the volumes and surfaces.
%
% Created by Haiyang Jin (29-March-2020)

if nargin < 2 || isempty(showT1)
    showT1 = 0;
end

% check if the path is available
filepath = fileparts(subjCode);

if isempty(filepath)
    % use SUBJECTS_DIR as the default subject path
    theSubjCode = fullfile(getenv('SUBJECTS_DIR'), subjCode);
else
    theSubjCode = subjCode;
end

% make sure the subjCode is available
assert(logical(exist(theSubjCode, 'dir')), 'Cannot find the path: %s.', theSubjCode);

if showT1
    fscmd_T1 = sprintf('%1$s/mri/T1.mgz ', theSubjCode);
else
    fscmd_T1 = '';
end

% create the commands
fscmd = sprintf(['freeview -v %2$s'...
    '%1$s/mri/brainmask.mgz ' ...
    '%1$s/mri/wm.mgz:colormap=heat:opacity=0.4 '...
    '-f %1$s/surf/lh.white:edgecolor=yellow '...
    '%1$s/surf/lh.pial:edgecolor=red '...
    '%1$s/surf/rh.white:edgecolor=yellow '...
    '%1$s/surf/rh.pial:edgecolor=red'], ...
    theSubjCode, fscmd_T1);

% run the commands
[status,cmdout] = system(fscmd);

if status
    disp(cmdout);
end

end