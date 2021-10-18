function [fvcmd, isok] = hcp_fvdrawlabel(subjCode, runstr, contra, varargin)
% [fvcmd, isok] = hcp_fvdrawlabel(subjCode, runstr, contra, varargin)
% 
% This function uses Freeview to display the first or second level results 
% in HCP. This function can be used to draw label.
%
% Inputs:
%    subjCode         <str> subject code.
%    runstr           <str> the run folder (level 2 folder).
%    contra           <str> the filename to be read.
%
% Varargin:
%    .template        <str> path starting within the subject folder and
%                      ending where the *.wb.spec file is. E.g.,
%                      'T1w/fsaverage_LR32k'.
%                  OR <int> 1 -> 'T1w/fsaverage_LR32k' (default1);
%                           2 -> 'MNINonLinear/fsaverage_LR32k';
%                           3 -> 'T1w/Native' (default1);
%                           4 -> 'MNINonLinear/Native';
%                           5 -> 'MNINonLinear'.
%    .fthresh         <str> or <num> the overlay threshold minimal 
%                      value.
%    .surfType        <str> available surface types are: inflated,
%                      midthickness, pial, very_inflated (default), white.
%    .runcmd          <boo> whether to run the freeview commands. 
%
% Outputs:
%    fvcmd            <str> freeview commands. 
%    isok             <boo> whether fvcmd is successful.
%
% Created by Haiyang Jin (2021-10-18)

%% Deal with inputs
defaultOpts = struct(...
    'template', '', ...
    'fthresh', '2,5', ...
    'surftype', 'very_inflated', ...
    'runcmd', 1 ...
    );
opts = fm_mergestruct(defaultOpts, varargin{:});

if isnumeric(opts.fthresh)
    opts.fthresh = num2str(opts.fthresh);
end
template = hcp_template(opts.template);

%% Sections for commands
% an empty cell to save commands
cmdinfo = cell(3,2); % surface, overlay, threshold

% thresholds
if ~isempty(opts.fthresh)
    cmdinfo(3,:) = repmat({sprintf(':overlay_threshold=%s', opts.fthresh)}, 1, 2);
end

% functional results (data on surface)
cfile = fullfile(hcp_funcdir(subjCode), runstr, [runstr '_hp200_s2_level2.feat'], contra);
gfiles = fm_cifti2gii(cfile);
cmdinfo(2,:) = gfiles';

% Surface files
surfdir = dir(fullfile(hcp_dir, subjCode, template, ...
    sprintf('%s.*.%s.*.gii', subjCode, opts.surftype)));
cmdinfo(1,:) = fullfile({surfdir.folder}, {surfdir.name});

% aparc
tmpTemplate = split(template, filesep);
tmpNum = regexp(tmpTemplate{2}, '\d*', 'Match');
aparcdir = dir(fullfile(hcp_dir, subjCode, 'MNINonLinear', tmpTemplate{2},  ...
    sprintf('%s.*.aparc.%s*.label.gii', subjCode, tmpNum{1})));
cmdinfo(4,:) = fullfile({aparcdir.folder}, {aparcdir.name});

%% The whole command
fvcmd = sprintf(['freeview -f %s:overlay=%s%s:annot=%s:annot_outline=true ' ...
    '-f %s:overlay=%s%s:annot=%s:annot_outline=true -colorscale -layout 1 -viewport 3d &'], ...
    cmdinfo{:});

if opts.runcmd
    isnotok = system(fvcmd);
    isok = ~isnotok;
else
    isok = 1;
end

end