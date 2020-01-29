function contraStruct = fs_mkcontrast(analysisList, contrasts, conditions, force)
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
%    contraStruct         a contrast structure which has three fieldnames.
%                         (analysisName: the ananlysis name; contrastName:
%                         the contrast name in format of a-vs-b;
%                         contrastCode: the commands to be used in
%                         FreeSurfer)
%                         contraStruct will also be saved as the Matlab
%                         file and its name will be the initials of all the
%                         conditions.
%
% Created by Haiyang Jin (19-Dec-2019)

if nargin < 4 || isempty(force)
    force = 0;
end

% filename of the Matlab file to be saved later
contraFn = sprintf('Contra_%s.mat', cellfun(@(x) x(1), conditions));

if exist(contraFn, 'file') && ~force
    load(contraFn, 'contraStruct');
    fprintf('contraStruct is loaded.\n');
    return;
end
    
% number of analysis names and contrasts
nAnalysis = numel(analysisList);
nContrast = size(contrasts, 1);

% empty structure for saving information
contraStruct = struct;
n = 0;

for iAnalysis = 1:nAnalysis
    
    % this analysis name
    analysisName = analysisList{iAnalysis};
    
    for iCon = 1:nContrast
        
        n = n + 1;
        
        % this contrast
        thisCon = contrasts(iCon, :);
        
        % the number of activation and control condition
        conditionNum = cellfun(@(x) find(startsWith(conditions, x)), thisCon, 'uni', false);
        
        % save the information
        contraStruct(n).analysisName = analysisName;
        
        % levels of activation and control
        nLevels = cellfun(@numel, conditionNum);
        
        % first part of contrast name
        contrNameAct = thisCon(1);
        contrNameStr = sprintf(['%s' repmat('%s', nLevels(1)-1) '-vs-'], contrNameAct{:});
        % first part of contrast code
        contrCodeStr = ['-a' repmat(' %d', 1, nLevels(1))];
        
        if nLevels(2) == 0
            conditionNum = conditionNum(1);
        else
            % second part of contrast name
            contrNameCon = thisCon(2);
            contrNameStrCon = sprintf(['%s' repmat('%s', nLevels(2)-1)], contrNameCon{:});
            contrNameStr = [contrNameStr, contrNameStrCon]; %#ok<AGROW>
            
            % second part of contrast code
            contrCodeStr = [contrCodeStr, ' -c' repmat(' %d', 1, nLevels(2))]; %#ok<AGROW>
        end
        
        contraStruct(n).contrastName = contrNameStr;
        contraStruct(n).contrastCode = sprintf(contrCodeStr, conditionNum{:});
        
        % created the commands
        fscmd = sprintf('mkcontrast-sess -analysis %s -contrast %s %s', ...
            analysisName, contraStruct(n).contrastName, contraStruct(n).contrastCode);
        
        system(fscmd)
    end
    
end

% save contraStr as Matlab file
save(contraFn, 'contraStruct', '-v7.3');
fprintf('contraStruct is saved in %s.\n', contraFn)

end