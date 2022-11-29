function fscmd = fv_drawlabel(subjCode, anaName, sigFile, labelname, varargin)
% fscmd = fv_drawlabel(subjCode, anaName, sigFile, labelname, varargin)
%
% This function uses "tksurfer" in FreeSurfer to draw label. You may want
% to use fs_drawlabel().
% 
% Inputs:
%    subjCode         <str> subject code in $SUBJECTS_DIR.
%    anaName          <str> the analysis name.
%    sigFile          <str> usually the sig.nii.gz from localizer scans.
%                      This should include the path to the file if needed.
%    labelname        <str> the label name you want to use for this
%                      label.
%
% Varargin:
%    .fthresh         <str> or <num> the overlay threshold minimal value.
%    .istk            <int> 1 for 'tksurfer' [note: not tksurfer-sess] and 
%                      0 for fv_surf(), which implements custom codes to
%                      run freeview. For FS5 and FS6, default is 1. For
%                      FS7, default is 0.
%    .coordsurf       <str> the surface name for showing coordinates, 
%                      default to 'white'.
%    .distmetric      <str> method to be used to calculate the distance. 
%                      Default to 'geodesic' (or 'dijkstra').
%    .addvalue        <boo> whether add the functional data/values used to
%                      create the label when 'freeview' is used. Default is
%                      1.
%    .extracmd        <str> extra commands for the viewer. Default is ''.
%    .runcmd          <boo> 0: do not run but only make fscmd; 1: run
%                      FreeSurfer commands. Default is 1.
%
% Output:
%    fscmd            <string> FreeSurfer commands used.
%    a label file saved in the label folder
%
% Tips:
% To invert the display of overlay, set extracmd as '-invphaseflag 1'.
% 
% Created by Haiyang Jin (10-Dec-2019)
% Furture development should include defining the limits of p-values.
%
% See also:
% fs_drawlabel

if nargin < 1
    fprintf('Usage: fscmd = fv_drawlabel(subjCode, anaName, sigFile, labelname, varargin);\n');
    return;
end

hemi = fm_2hemi(anaName);

defaultOpts = struct( ...
    'fthresh', '', ...
    'istk', fs_version(1) < 7, ... % the default viewer
    'coordsurf', 'white', ...
    'distmetric', 'geodesic', ...
    'addvalue', 1, ...
    'extracmd', '', ...
    'runcmd', 1);
opts = fm_mergestruct(defaultOpts, varargin{:});

fthresh = opts.fthresh;
if isnumeric(fthresh)
    fthresh = num2str(fthresh);
end

% find the template for this analysis
template = fs_2template(anaName, '', 'self');
trgSubj = fs_trgsubj(subjCode, template);

% print the information
fprintf('\nSubjCode: %s\nAnalysis: %s\nLabel: %s\nfthresh: %s\n\n', ...
    subjCode, anaName, labelname, fthresh);

%% Print more information on activations
% read the surface
surffn = [fm_2hemi(anaName) '.' opts.coordsurf];
[coords, faces] = fs_readsurf(surffn, subjCode);

% get the reference coordinates
[labelTemp, refcoord] = sf_roitemplate(labelname);

% read the information of the temporary label
labelMatTemp = fs_readlabel(labelTemp, subjCode);
if isempty(labelMatTemp)
    fs_label2label('fsaverage', labelTemp, subjCode, 'samename');
    labelMatTemp = fs_readlabel(labelTemp, subjCode);
end

% update coordinates in labelMatTemp
labelMatTemp(:, 2:4) = coords(labelMatTemp(:,1), :);

% update values in labelMatTemp
vals = fm_readimg(sigFile);
labelMatTemp(:,5) = vals(labelMatTemp(:,1)); % add values

% approximation of the reference coordinates
[~, approI] = min(arrayfun(@(x) pdist2(refcoord, labelMatTemp(x, 2:4)), ...
    1:size(labelMatTemp,1)));
refappro = labelMatTemp(approI, :);

% Get clusters for positive and negative separately
labelMatPosi = labelMatTemp;
labelMatNega = labelMatTemp;

labelMatPosi(labelMatPosi(:,5)<0, 5) = 0;
labelMatNega(labelMatNega(:,5)>0, 5) = 0;

clusterIdxPosi = sf_clusterlabel(labelMatPosi, faces, str2double(fthresh));
clusterIdxNega = sf_clusterlabel(labelMatNega, faces, str2double(fthresh));

% Gather information for positive
outPosi = maxminrow(labelMatPosi, clusterIdxPosi, refappro);
outPosi.Geo = round(sf_geodesic(coords, faces, labelMatTemp(:,1), ...
    refappro(1,1), outPosi.VtxIdx, opts.distmetric), 1);
outPosi.Euc = round(arrayfun(@(x) pdist2(refcoord, outPosi.SelfCoords(x,:)), ...
    1:size(outPosi, 1)), 1)';
outPosi.MNI = round(fs_fsavg2mni(fs_self2fsavg(outPosi.SelfCoords, subjCode)), 1);
outPosi.surface = repmat(surffn, size(outPosi,1), 1);

disp(sortrows(outPosi, 'Euc')); % disp positive

% Gather information for negative
outNega = maxminrow(labelMatNega, clusterIdxNega, refappro);
outNega.Geo = round(sf_geodesic(coords, faces, labelMatTemp(:,1), ...
    refappro(1,1), outNega.VtxIdx, opts.distmetric), 1);
outNega.Euc = round(arrayfun(@(x) pdist2(refcoord, outNega.SelfCoords(x,:)), ...
    1:size(outNega, 1)), 1)';
outNega.MNI = round(fs_fsavg2mni(fs_self2fsavg(outNega.SelfCoords, subjCode)), 1);
outNega.surface = repmat(surffn, size(outNega,1), 1);

disp(sortrows(outNega, 'Euc')); % disp negative

%% Identiy labels 
% create FreeSurfer command and run it
titleStr = sprintf('%s==%s==%s', subjCode, labelname, anaName);

if opts.istk
    % use tksurfer (cannot be tested now)
    fscmd = sprintf('tksurfer %s %s inflated -aparc -overlay %s -title %s %s',...
        trgSubj, hemi, sigFile, titleStr, opts.extracmd);
    if ~isempty(fthresh)
        fscmd = sprintf('%s -fthresh %s', fscmd, fthresh);
    end
    tmpLabelname = 'label.label';
else
    % use freeview
    fvopts.surftype = 'inflated';
    fvopts.threshold = [fthresh ',5'];
    fvopts.annot = 'aparc';
    fvopts.overlay = sigFile;
    fvopts.runcmd = 0;
    % get the surface codes
    tmpMgz = fullfile(getenv('SUBJECTS_DIR'), subjCode, 'surf', ...
        sprintf('%s.w-g.pct.mgh', hemi));
    [~, fscmd] = fv_surf(tmpMgz, trgSubj, fvopts);
    tmpLabelname = fullfile('label', 'label_1.label');
end

% finish this command if do not need to run fscmd
if ~opts.runcmd; return; end
system(fscmd);

%%%%%%%%%%%%%%%% Manual working in FreeSurfer %%%%%%%%%%%%%%%%%%%%%%%%%%%%
% IMPORTANT: Please make sure you started X11
% 1. click any vertex in the region;
% 2. fill it with "similar" vertices;
%    1.Custom Fill;
%    2.make sure "Up to and including paths" and "up to funcitonal values
%      below threhold" are selected;
%    3.click "Fill".
% 3. Save that area as a label file;
% NOTE: please name the label as label.label in the folder
% ($SUBJECTS_DIR/subjCode/label.label) Basically, you only need to delect
% the "/" in the default folder or filename
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Rename the label file
% created an empty file with the label filename
labelFile = fullfile(getenv('SUBJECTS_DIR'), subjCode, 'label', labelname);

% rename and move this label file
tmpLabelFile = fullfile(getenv('SUBJECTS_DIR'), trgSubj, tmpLabelname);

if logical(exist(tmpLabelFile, 'file'))

    tooverwrite = 'move';
    % throw warning if the target label exists
    if logical(exist(labelFile, 'file'))
        fig1 = uifigure;
        tooverwrite = uiconfirm(fig1, 'Overwrite the target label file?', ...
            'The target label file already exists...', 'Icon', 'warning');
        close(fig1);
    end

    switch tooverwrite
        case 'move'
            movefile(tmpLabelFile, labelFile);
            fprintf('Label %s is created.\n', labelname);
        case 'OK'
            movefile(tmpLabelFile, labelFile);
            fprintf('Label %s is overwritten.\n', labelname);
        case 'Cancel'
            delete(tmpLabelFile)
            fprintf('The old %s is not updated.\n', labelname);
    end
end

% Add sig values if freeview is used
if ~opts.istk && opts.addvalue
    fs_labelval(labelname, subjCode, sigFile);
end

end

function out = maxminrow(labelMat, clusterIdx, refappro)
% Get the rows with maximum and minimum values

if all(labelMat(:, 5)<=0)
    extreme=@min;
elseif all(labelMat(:, 5)>=0)
    extreme=@max;
else
    error('Unknown situations.');
end

outcell = cell(max(clusterIdx), 1);

for iClu = 1:max(clusterIdx)
    tmpmat = labelMat(clusterIdx==iClu,:);
    [~, i] = extreme(tmpmat(:,5));
    outcell{iClu} = tmpmat(i, :);

end %nClu

outmat = vertcat(outcell{:});
outmat = vertcat(refappro, outmat); % add the reference vertex

VtxIdx = outmat(:,1);
SelfCoords = round(outmat(:, 2:4), 1);
Val = round(outmat(:, 5), 1);

out = table(VtxIdx, SelfCoords, Val);

end % maxminrow