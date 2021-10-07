function hcp_par2ev(subjCode, runinfo)
% hcp_par2ev(subjCode, runinfo)
% 
% Convert *.par file used in FreeSurfer as EV files (three column format)
% used in HCP (or FSL). 
% 
% Inputs:
%    subjCode      <string> subject code.
%    runinfo       <cell string> list of run folders. more see hcp_runlist.
%               OR <string> string pattern (wildcard) to match run folders.
%
% Output:
%    EV files for each condition.
%
% Created by Haiyang Jin (2021-10-7)
%
% see also:
% fsl_par2ev

% setup
if ~exist('runinfo', 'var') || isempty(runinfo)
    runinfo = '*fMRI*';
end

% get the run list
runlist= hcp_runlist(subjCode, runinfo);

% create ev files for each run
cellfun(@fsl_par2ev, fullfile(hcp_funcdir(subjCode), runlist));

end