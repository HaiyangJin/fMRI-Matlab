function fs_selxavg3(sessidfile, analysisList)
% This function runs the analysis with all contrasts
%
% Inputs:
%    sessidfile          the file contains all subject code (bold)
%    analysisList        the list of analysis names
%
% Created by Haiyang Jin (19/12/2019)

% run the analysis 
cellfun(@(x) system(sprintf('selxavg3-sess -sf %s -analysis %s', sessidfile, x)), analysisList);
