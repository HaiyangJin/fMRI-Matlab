function fsl_par2ev(parfilename, evPath)
% fsl_par2ev(parfilename, evPath)
%
% Convert *.par file used in FreeSurfer as EV files (three column format)
% used in FSL. The three columns are stimulus onset, stimulus duration and
% magnitude (usually all 1).
%
% Inputs:
%    parfilename    <string> the filename of par file.
%    evPath         <string> where to save the output EV files.
%
% Output:
%    EV files for each condition.
%
% Created by Haiyang Jin (2021-09-27)

if ~exist('evPath', 'var') || isempty(evPath)
    evPath = fullfile('.', 'par2ev');
end
fm_mkdir(evPath);

% obtain all conditions and remove the baseline
parT = fs_readpar(parfilename, 0);
evs = unique(parT.Condition);
evs = evs(evs ~= 0); % remove the baseline 0

% save EV files for each condition separately
for iev = 1:length(evs)
    
    theev = evs(iev);
    thisT = parT(parT.Condition == theev, :);
    
    % condition name
    fn = lower(thisT.Label{1});
    
    % remove unused columns
    thisT.Condition = [];
    thisT.Label = [];
    
    % save the EV file
    writetable(thisT, fullfile(evPath, fn), 'Delimiter',' ', 'WriteVariableNames',false);
    
end

end
