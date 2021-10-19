function [status, hcpcmd, specFile] = hcp_view(subjCode, template, specFn, fileList, runcmd)
% [status, hcpcmd, specFile] = hcp_view(subjCode, template, specFn, fileList, runcmd)
%
% This function shows the *.wb.spec file with HCP workbench.
%
% Inputs:
%    subjCode         <str> subject code.
%    template         <str> path starting within the subject folder and
%                      ending where the *.wb.spec file is. E.g.,
%                      'T1w/fsaverage_LR32k'.
%                  OR <int> 1 -> 'T1w/fsaverage_LR32k' (default1);
%                           2 -> 'MNINonLinear/fsaverage_LR32k';
%                           3 -> 'T1w/Native' (default1);
%                           4 -> 'MNINonLinear/Native';
%                           5 -> 'MNINonLinear'.
%    specFn           <str> the spec filename. Default is '*.wb.spec'.
%    fileList         <cell str> a list of files to be added the Scene.
%    runcmd           <logic> whether run the hcp commands (default is 1).
%
% Outputs:
%    status           <int array> the status of running cmds. Only 0
%                      suggests that the commands completed successfully.
%    hcpcmd           <str> the hcp command.
%    specFile         <str> full path to the *.wb.spec file.
%
% % Example 1:
% hcp_view(subjCode);
%
% Created by Haiyang Jin (2021-10-05)

if ~exist('template', 'var') || isempty(template)
    template = '';
end
template = hcp_template(template);

if ~exist('specFn', 'var') || isempty(specFn)
    specFn = '*.wb.spec';
end

if ~exist('fileList', 'var') || isempty(fileList)
    fileList = {''};
end
if ischar(fileList); fileList = {fileList}; end
% cmd for files to be added
cmd_file = sprintf(repmat(' %s', 1, length(fileList)), fileList{:});

if ~exist('runcmd', 'var') || isempty(runcmd)
    runcmd = 1;
end

% Identify the spec file
templatePath = fullfile(hcp_dir, subjCode, template, specFn);
specDir = dir(templatePath);
specFiles = {specDir.name};

assert(length(specFiles)==1, 'More than one spec file was found.\n%s', ...
    sprintf('%s ', specFiles{:}));

specFile = fullfile(specDir.folder, specDir.name);
fprintf('\nThe spec file is: \n %s\n', specFile);

% create the cmd
hcpcmd = sprintf('wb_view %s%s', specFile, cmd_file);
hcpcmd = fm_cleancmd(hcpcmd);

% run the cmd
if runcmd
    [status, cmdout] = system(hcpcmd);
    assert(~status, 'Command failed for "hcp_view". \n%s', cmdout);
else
    status = -1;
end

end