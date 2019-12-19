function contra_str = fs_mkcontrast(analysisList, contrasts, conditions)
% This function creates contrast and run mkcontrast-sess in FreeSurfer
%
% Inputs:
%    analysisList         a list of all analysis names
%    contrasts            a cell of contrasts to be created. One row is one
%                         contrast; the conditions in the first cell is the
%                         activation condition; the conditions in the
%                         second cell is the control condition. (These will
%                         be used to set the contrast name later)
%    conditions           the full names of all conditions
% Output:
%    contra_str           a contrast structure which has three fieldnames.
%                         (analysisName: the ananlysis name; contrastName:
%                         the contrast name in format of a-vs-b;
%                         contrastCode: the commands to be used in
%                         FreeSurfer)
%
% Created by Haiyang Jin (19/12/2019)

% number of analysis names and contrasts
nAnalysis = numel(analysisList);
nContrast = size(contrasts, 1);

% empty structure for saving information
contra_str = struct;
n = 0;

for iAnalysis = 1:nAnalysis
    
    % this analysis name
    analysisName = analysisList{iAnalysis};
    
    for iCon = 1:nContrast
        
        n = n + 1;
        
        % this contrast
        thisCon = contrasts(iCon, :);
        
        % the number of activation and control condition
        conditionNum = cellfun(@(x) find(startsWith(conditions, x)), thisCon);
        
        % save the information
        contra_str(n).analysisName = analysisName;
        contra_str(n).contrastName = sprintf('%s-vs-%s', thisCon{:});
        contra_str(n).contrastCode = sprintf('-a %d -c %d', conditionNum);
        
        % created the commands
        fscmd = sprintf('mkcontrast-sess -analysis %s -contrast %s %s', ...
            analysisName, contra_str(n).contrastName, contra_str(n).contrastCode);
        
        system(fscmd)
    end
    
end