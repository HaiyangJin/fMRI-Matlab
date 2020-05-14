function fs_cvn_print1st(sessList, anaList, labelList, outPath, varargin)
% fs_cvn_print1st(sessList, anaList, labelList, outPath, varargin)
%
% This function prints the first-level results and the labels in label/.
%
% Inputs:
%    sessList        <cell string> list of session codes (in funcPath).
%    anaList         <cell string> list of analysis names. Default is empty
%                     and no overlay will be displayed.
%    labelList       <cell string> list of label names or list of contrast
%                     names.
%    outPath         <string> where to save the output images. [current
%                     folder by default].
%
% Optional inputs (varargin):
%    'waitbar'       <logical> 1 [default]: show the wait bar; 0: do not
%                     show the wait bar.
%    'sigFn'         <string> name of the to-be-printed file [Default is
%                     sig.nii.gz].
%    'viewpt'        <integer> the viewpoitns to be used. More see
%                     fs_cvn_lookup.m. Default is -2.
%    'thresh'        <numeric> display threshold. Default is 1.3010 (abs).
%                     For example, '1.3i' will display values <-1.3 and
%                     >1.3; '1.3' will display values > 1.3 (but not
%                     <-1.3).
%    'clim'          <numeric array> limits for the color map. The Default
%                     empty, which will display responses from %1 to 99%.
%    'cmap'          <string or colormap array> use which color map,
%                     default is jet(256).
%                    'fsheatscale': use the heatscale in FreeSurfer; 'thresh'
%                     will be used as 'fmin' and the maximum absolute value
%                     of 'clim' will be used as 'fmax'.
%    'roicolors'     <numeric array> colors to be used for the label roi
%                     masks.
%    'lookup'        <> setting used for cvnlookupimage.
%    'subfolder'     <numeric> which subfolder to save the outputs. 0: no
%                     subfolder [Default]; 1: use subjCode; 2: use the Label.
%    'suffixstr'     <string> extra strings to be added at the end of the
%                     image name. Default is ''.
%    'annot'         <string> which annotation will be used. Default is
%                     '', i.e., not display annotation file.
%    'markpeak'      <logical> mark the location of the peak response.
%                     Default is 0.
%    'showinfo'      <logical> show label information in the figure.
%                     Default is 0, i.e., do not show the label information.
%    'wantfig'       <logical/integer> Default is 2, i.e., do not show the
%                     figure. More please check fs_cvn_lookup.
%    'visualimg'     <string> 'off' [default]: do not visualize the image;
%                     'on': visualize the image.
%    'cvnopts'       <cell> extra options for cvnlookupimages.m.
%    'funcPath'      <string> the path to functional folder [Default is
%                     $FUNCTIONALS_DIR].
%
% Output:
%    images of first-level analysis results.
%
% Created by Haiyang Jin (20-Apr-2020)

%% Deal with intputs

defaultOpts = struct(...
    'waitbar', 1, ...
    'sigfn', 'sig.nii.gz', ...
    'viewpt', -2, ...
    'thresh', [], ...
    'clim', [], ...
    'cmap', jet(256), ...
    'roicolors', {fs_colors}, ...
    'lookup', [], ...
    'subfolder', 1, ...
    'suffixstr', '', ...
    'annot', '', ...
    'markpeak', 0, ... % mark the peak response in the label
    'showinfo', 0, ...
    'wantfig', 2, ...
    'visualimg', 'off', ...
    'cvnopts', {{}}, ...
    'funcpath', getenv('FUNCTIONALS_DIR'), ...
    'strupath', getenv('SUBJECTS_DIR'));  % not in use now

opts = fs_mergestruct(defaultOpts, varargin);

% show progress bar (if needed)
showWaitbar = opts.waitbar;
if showWaitbar
    waitHandle = waitbar(0, 'Preparing for printing first-level results...');
end

% generate settings
viewpt = opts.viewpt;
clim = opts.clim;
cmap = opts.cmap;  % use jet(256) as the colormap
subfolder = opts.subfolder+1; % subfolder for saving the images
annot = opts.annot;  % the annotation file
lookup = opts.lookup;
imgNameExtra = opts.suffixstr;
wantfig = opts.wantfig;  % do not show figure with fs_cvn_lookuplmv.m
roicolors = opts.roicolors;
showInfo = opts.showinfo;
markPeak = opts.markpeak;
cnvopts = opts.cvnopts;

sigFn = opts.sigfn;
thresh = opts.thresh;  % 0.05
visualImg = opts.visualimg;
funcPath = opts.funcpath;

if ~isempty(imgNameExtra) && ~startsWith(imgNameExtra, ' || ')
    imgNameExtra = [' || ' imgNameExtra];
end

% some maybe nonsense default
if ischar(sessList); sessList = {sessList}; end
if ~exist('anaList', 'var') || isempty(anaList)
    anaList = {'nooverlay.lh', 'nooverlay.rh'};
elseif ischar(anaList)
    anaList = {anaList};
end
if ~exist('labelList', 'var') || isempty(labelList)
    labelList = fs_ana2con(anaList);
elseif ischar(labelList)
    labelList = {labelList};
end

% output path
if ~exist('outPath', 'var') || isempty(outPath)
    outPath = fullfile(pwd, 'First_level_results');
end
% outPath = fullfile(outPath, sigFn);

nLabel = numel(labelList);
nSess = numel(sessList);

%% For each label
for iLabel = 1:nLabel
    
    theseLabel = labelList{iLabel};
    if ischar(theseLabel); theseLabel = {theseLabel}; end
    
    [~, nHemiTemp] = fs_hemi_multi(theseLabel);
    assert(nHemiTemp == 1, 'These labels are not for the same hemisphere.');
    % the contrast, hemi, and threshold for the first label will
    % be used for printing the activation.
    theLabel = theseLabel{1};
    nTheLabel = numel(theseLabel);
    
    % the contrast and the hemi information
    thisCon = fs_2contrast(theLabel);
    labelHemi = fs_2hemi(theLabel);
    
    % threshold for plotting
    thresh0 = fs_2sig(theLabel)/10 * 1i;
    if ~isempty(thresh)
        % use thresh if it is not empty
        thresh0 = thresh;
    elseif isempty(thresh0)
        % use default 1.3 if they are both empty
        thresh0 = 1.3i;
    end
    
    % identify the cooresponding analysis name
    theseAna = endsWith(anaList, labelHemi);
    theAnaList = anaList(theseAna);
    nAna = numel(theAnaList);
    
    for iAna = 1:nAna
        
        thisAna = theAnaList{iAna};
        % update thisHemi based on the analysis name
        thisHemi = fs_2hemi(thisAna);
        
        if isempty(labelHemi)
            theLabelName = [theLabel '_' thisHemi];
        else
            theLabelName = theLabel;
        end
        
        for iSess = 1:nSess
            
            % session and subject code
            thisSess = sessList{iSess};
            subjCode = fs_subjcode(thisSess, funcPath);
            
            % waitbar
            if showWaitbar
                waitPerc = ((iLabel-1)*nSess*nAna + (iAna-1)*nSess + iSess-1) / (nLabel*nSess*nAna);
                waitMsg = sprintf('Label: %s   nTheLabel: %d   SubjCode: %s \n%0.2f%% finished...', ...
                    strrep(theLabelName, '_', '\_'), nTheLabel, strrep(subjCode, '_', '\_'), waitPerc*100);
                waitbar(waitPerc, waitHandle, waitMsg);
            end
            
            % the target subject [whose coordinates will be used
            trgSubj = fs_trgsubj(subjCode, fs_2template(thisAna, '', 'self'));
            
            if ~startsWith(thisAna, 'nooverlay')
                % full path to the to-be-printed file
                sigFile = fullfile(funcPath, thisSess, 'bold', thisAna, thisCon, sigFn);
            else
                tempNVtx = size(fs_readsurf([thisHemi '.inflated'], trgSubj), 1);
                sigFile = zeros(tempNVtx, 1); 
                tempLabelMat = fs_readlabel(theLabel, subjCode);
                sigFile(tempLabelMat(:, 1)) = tempLabelMat(:, 5);
            end
            
            % read data
            thisSurf = fs_cvn_valstruct(sigFile, thisHemi);
            nVtx = numel(thisSurf.data);
            
            % set colormap limit based on the data if necessary
            if isempty(clim)
                theunique = sort(unique(thisSurf.data(:)))';
                thisclim0 = theunique([2, end]);
            else
                thisclim0 = clim;
            end
            
            % process colormap if necessary
            if isreal(thresh0)
                fmin = thresh0;
            else
                fmin = imag(thresh0);
            end
            
            if ischar(cmap) && strcmp(cmap, 'fsheatscale')
                fmax = max(abs(thisclim0));
                cmap = fs_heatscale(fmin, fmax);
                thisclim0 = [-fmax, fmax];
            end
            
            % read the label and remove empty cells
            thisMat = cellfun(@(x) fs_readlabel(x, subjCode), theseLabel, 'uni', false);
            isEmptyMat = cellfun(@isempty, thisMat);
            thisMat(isEmptyMat) = [];
            
            % create roi mask for the label and roi name string
            maskStr = '';
            if isempty(thisMat)
                rois = [];
                roicolor = [];
                nTheLabel = 1;
                if endsWith(theLabelName, '.label')
                    maskStr = 'NoLabel || ';
                end
            else
                thisRoi = cellfun(@(x) makeroi(nVtx, x(:, 1)), thisMat, 'uni', false)';
                nTheLabel = numel(thisRoi);
                roicolor = roicolors(1:nTheLabel, :);
                
                % mark the peak in the label
                if markPeak
                    tempLabelT = fs_labelinfo(theseLabel, subjCode, ...
                        'bycluster', 1, 'fmin', fmin);
                    rois = [thisRoi; arrayfun(@(x) makeroi(nVtx, x), tempLabelT.VtxMax, 'uni', false)];
                    roicolor = repmat(roicolor, size(rois, 1), 1);
                else
                    rois = thisRoi;
                end
            end
            
            % create parts of the output filename
            theLabelNames = theseLabel(~isEmptyMat);
            if all(isEmptyMat); theLabelNames = {theLabelName}; end
            labelNames = sprintf(['%s' repmat(' || %s', 1, nTheLabel-1)], theLabelNames{:});
            
            % process the extra setting for printing
            thisExtraopts = [{'cmap',cmap, 'clim', thisclim0}, cnvopts];
            
            %% Make the image
            %%%%%%% make image for this file %%%%%%%%
            [~, lookup, rgbimg] = fs_cvn_lookup(trgSubj, viewpt, thisSurf, lookup, ...
                'cvnopts', thisExtraopts, ...
                'wantfig', wantfig, ...
                'thresh', thresh0, ...
                'roimask', rois, ...
                'roicolor', roicolor, ...
                'roiwidth', repmat({1}, numel(rois), 1), ...
                'annot', annot);
            close all;
            
            % clear lookup if necessary
            if ~strcmp(trgSubj, 'fsaverage')
                lookup = [];
            end
            
            %% Save the image
            % set the figure name and save it
            fig = figure('Visible',visualImg);
            imshow(rgbimg); % display lookup results (imagesc + colorbar)
            
            % obtain the contrast name as the figure name
            imgName = sprintf('%s%s || %s%s', maskStr, labelNames, thisSess, imgNameExtra);
            set(fig, 'Name', imgName);
            
            % Load and show the (first) label related information
            if showInfo && ~all(isEmptyMat)
                labelCell = cellfun(@(x) fs_labelinfo(x, subjCode, ...
                    'bycluster', 1, 'fmin', fmin), theLabelNames, 'uni', false);
                labelTable = vertcat(labelCell{:});
                labelTable.Properties.VariableNames{3} = 'No';
                labelTable.SubjCode = [];
                labelTable.fmin = [];
                
                pos = get(fig, 'Position'); %// gives x left, y bottom, width, height
                switch viewpt
                    case 3
                        pos4Extra = 1500;
                    case {'ffa'}
                        pos4Extra = pos(4);
                    otherwise
                        pos4Extra = max(ceil(pos(4)/pos(3)*1000)-600, 400);
                end
                set(fig, 'Position', [pos(1:2) max(1150, pos(3)) pos(4)+pos4Extra]);
                % Get the table in string form.
                TString = evalc('disp(labelTable)');
                % Use TeX Markup for bold formatting and underscores.
                TString = strrep(TString,'<strong>','\bf');
                TString = strrep(TString,'</strong>','\rm');
                TString = strrep(TString,'_','\_');
                % Get a fixed-width font.
                FixedWidth = get(0,'FixedWidthFontName');
                % Output the table using the annotation command.
                annotation(gcf,'Textbox','String',TString,'Interpreter','Tex',...
                    'FontName',FixedWidth,'Units','Normalized',...
                    'Position',[0 0 1 pos4Extra/4/(pos4Extra/2 + pos(4))],'FontSize',12,'LineStyle','none');
            end
            
            colormap(cmap);
            c = colorbar;
            caxis(thisclim0);
            c.Ticks = ceil(thisclim0(1)):1:floor(thisclim0(2)); 
            c.TickLength = 0.02;
            
            % print the figure
            subfolders = {'', subjCode, theLabel};
            
            theOutPath = fullfile(outPath, subfolders{subfolder});
            if ~exist(theOutPath, 'dir'); mkdir(theOutPath); end
            thisOut = fullfile(theOutPath, [imgName '.png']);
            
            try
                % https://github.com/altmany/export_fig
                export_fig(thisOut, '-png','-transparent','-m2');
            catch
                print(fig, thisOut,'-dpng');
            end
            
            if strcmp(visualImg, 'off')
                close(fig);
            end
        end   % iSess
    end   % iAna
end   % iLabel

if showWaitbar; close(waitHandle); end

end

function theroi = makeroi(nVtx, maskVtx)
% create a roi binary mask
theroi = zeros(nVtx, 1);
theroi(maskVtx) = 1;
end