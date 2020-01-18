function fs_editanalysis(analysisName, varName, varValue)
% This function changes the analysis information manually.
%
% Inputs:
%    analysisName         analysisName with path
%    varName              the name of the variable to be changed
%    varValue             the new value for that variable
% Output:
%    a new analysis.info with updated information
%
% Created by Haiyang Jin (19/12/2019)

% the old analysis.info file
anaInfoFile = fullfile(analysisName, 'analysis.info');
fidOld = fopen(anaInfoFile, 'r');

% created a temporary file
tempFile = fullfile(analysisName, 'tmpanalysis.info');
fidTemp = fopen(tempFile, 'w');

while(1)
    % scroll through any blank lines or comments %

    tline = fgetl(fidOld);
    if ~isempty(tline) && (tline(1) == -1); break; end
    
    % Read the key %
    key = sscanf(tline,'%s',1);
%     tlinesplit = splitstring(tline);
    if strcmp(key,varName)
        fprintf(fidTemp, '%s %s\n', varName, varValue);
    else
        fprintf(fidTemp, '%s\n', tline);
    end 
end

% close both files
fclose(fidOld);
fclose(fidTemp);

% move the temporary file to overwrite the old analysis.info
movefile(tempFile, anaInfoFile);

end