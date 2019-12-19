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
anainfo_file = fullfile(analysisName, 'analysis.info');
fid_old = fopen(anainfo_file, 'r');

% created a temporary file
tmp_file = fullfile(analysisName, 'tmpanalysis.info');
fid_tmp = fopen(tmp_file, 'w');

while(1)
    % scroll through any blank lines or comments %

    tline = fgetl(fid_old);
    if ~isempty(tline) && (tline(1) == -1); break; end
    
    % Read the key %
    key = sscanf(tline,'%s',1);
%     tlinesplit = splitstring(tline);
    if strcmp(key,varName)
        fprintf(fid_tmp, '%s %s\n', varName, varValue);
    else
        fprintf(fid_tmp, '%s\n', tline);
    end 
end

% close both files
fclose(fid_old);
fclose(fid_tmp);

% move the temporary file to overwrite the old analysis.info
movefile(tmp_file, anainfo_file);

end