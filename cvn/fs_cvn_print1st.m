function varargout = fs_cvn_print1st(sessList, anaList, labelList, outPath, varargin)
% fs_cvn_print1st(sessList, anaList, labelList, outPath, varargin)
%
% This function prints the first-level results and the labels in label/.
%
% Inputs:
%    sessList        <cell str> list of session codes in $FUNCTIONALS_DIR.
%    anaList         <cell str> list of analysis names. Default is empty
%                     and the overlay in the label file will be displayed.
%    labelList       <cell str> list of label names.
%                  OR list of contrast names.
%    outPath         <str> where to save the output images. [current
%                     folder by default].
%
% Optional inputs (varargin):
%    'overlay'       <num vec> values to be displayed on surface. 
%    'waitbar'       <boo> 1 [default]: show the wait bar; 0: do not
%                     show the wait bar.
%    'sigfn'         <str> name of the to-be-printed file [Default is
%                     sig.nii.gz].
%    'dispsig'       <boo> 1 [default]: draw the data in sig file 
%                     (overlay) on the surface; 0: do not display data.
%    'viewpt'        <int> the viewpoitns to be used. More see
%                     fs_cvn_lookup.m. Default is -2.
%    'thresh'        <num> display threshold. Default is 1.3010 (abs).
%                     For example, '1.3i' will display values <-1.3 and
%                     >1.3; '1.3' will display values > 1.3 (but not
%                     <-1.3).
%    'dispcolorbar'  <boo> whether display colorbar. 1 [default]: show
%                     the colorbar; 0: do not show the colorbar.
%    'clim'          <num array> limits for the color map. The Default
%                     empty, which will display responses from %1 to 99%.
%    'cmap'          <str or colormap array> use which color map,
%                     default is jet(256).
%                    'fsheatscale': use the heatscale in FreeSurfer; 'thresh'
%                     will be used as 'fmin' and the maximum absolute value
%                     of 'clim' will be used as 'fmax'.
%    'roicolors'     <num array> colors to be used for the label roi
%                     masks.
%    'lookup'        <> setting used for cvnlookupimage.
%    'subfolder'     <num> which subfolder to save the outputs. 0: no
%                     subfolder; 1: use subjCode [Default]; 2: use the Label.
%    'suffixstr'     <str> extra strings to be added at the end of the
%                     image name. Default is ''.
%    'annot'         <str> which annotation will be used. Default is
%                     '', i.e., not display annotation file.
%    'gminfo'        <boo> 0: do not show global maxima information;
%                     1 [default]: only show the global maxima information,
%                     but not the maxresp; 2: show both global maxima and 
%                     maxresp information.
%    'markpeak'      <boo> mark the location of the peak response.
%                     Default is 0.
%    'showinfo'      <boo> show label information in the figure.
%                     Default is 0, i.e., do not show the label information.
%    'shortinfo'     <boo> show the short version of the information
%                     (i.e., MNI305 coordinates, size and number of
%                     vertices). Default is 0. When 'shortinfo' is set as
%                     1, 'showinfo' will be omitted.
%    'peakonly'      <boo> 1 [default]: only show the peak when identify
%                     global maxima; 0: show the outline of the label.
%    'wantfig'       <boo/int> Default is 2, i.e., do not show the
%                     figure. More please check fs_cvn_lookup.
%    'visualimg'     <str> 0 [default]: do not visualize the image;
%                     '1': visualize the image.
%    'imgext'        <str> image file extension. Choices are 'png' (default),
%                     'pdf'. 
%    'drawroi'       <boo> whether draw ROI with fs_cvn_lookup. Default
%                     is 0.
%    'cvnopts'       <cell> extra options for cvnlookupimages.m.
%    'funcdir'      <str> the path to functional folder [Default is
%                     $FUNCTIONALS_DIR].
%
% Output:
%    images of first-level analysis results.
%
% Example for drawing ROI:
% fs_cvn_print1st(sessCode, anaName, '', outPath, 'viewpt', 3, 'drawroi', 1);
% Rmask = drawroipoly(himg,lookup);
% lfile = fs_mklabel(Rmask, subjCode, 'temp.label');
% % quick way to check the mask
% cvnlookup(subjCode,3,Rmask,[0 1],gray);
%
% Created by Haiyang Jin (20-Apr-2020)

%% Deal with intputs

defaultOpts = struct(...
    'overlay', '', ...
    'waitbar', 1, ...
    'sigfn', 'sig.nii.gz', ...
    'dispsig', 1, ...
    'viewpt', -2, ...
    'thresh', [], ...
    'dispcolorbar', 1, ...
    'clim', [], ...
    'cmap', jet(256), ...
    'roicolors', {fm_colors}, ...
    'lookup', [], ...
    'subfolder', 1, ... % subfolder for saving the images
    'suffixstr', '', ...
    'annot', '', ... % the annotation file
    'gminfo', 1, ...
    'showpeak', 0, ... % mark the peak response in the label
    'showinfo', 0, ...
    'shortinfo', 0, ...
    'peakonly', 0, ...
    'wantfig', 2, ... % do not show figure with fs_cvn_lookuplmv.m
    'visualimg', 'off', ...
    'imgext', 'png', ...
    'drawroi', 0, ...
    'cvnopts', {{}}, ...
    'funcdir', getenv('FUNCTIONALS_DIR'), ...
    'strudir', getenv('SUBJECTS_DIR'));  % not in use now

opts = fm_mergestruct(defaultOpts, varargin);

% show progress bar (if needed)
showWaitbar = opts.waitbar;
if showWaitbar
    waitHandle = waitbar(0, 'Preparing for printing first-level results...');
end

% generate settings
viewpt = opts.viewpt;
clim = opts.clim;
cmap = opts.cmap;  % use jet(256) as the colormap
imgNameExtra = opts.suffixstr;

if ~isempty(imgNameExtra) && ~startsWith(imgNameExtra, ' || ')
    imgNameExtra = [' || ' imgNameExtra];
end

% some maybe nonsense default
if ischar(sessList); sessList = {sessList}; end
if ~exist('anaList', 'var') || isempty(anaList)
    anaList = {'labeloverlay.lh', 'labeloverlay.rh'};
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
    theseLabel(cellfun(@isempty, theseLabel)) = [];
    
    % make sure theseLabel is a row vector
    nTheLabel = numel(theseLabel);
    if nTheLabel == size(theseLabel, 1)
        theseLabel = theseLabel';
    end
    
    [~, nHemiTemp] = fm_hemi_multi(theseLabel);
    assert(nHemiTemp == 1, 'These labels are not for the same hemisphere.');
    % the contrast, hemi, and threshold for the first label will
    % be used for printing the activation.
    theLabel = theseLabel{1};
    
    % the contrast and the hemi information
    thisCon = fm_2contrast(theLabel);
    labelHemi = fm_2hemi(theLabel);
    
    % threshold for plotting
    thresh0 = fm_2sig(theLabel)/10 * 1i;
    if ~isempty(opts.thresh)
        % use thresh if it is not empty
        thresh0 = opts.thresh;
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
        thisHemi = fm_2hemi(thisAna);
        
        if isempty(labelHemi)
            theLabelName = [theLabel '_' thisHemi];
        else
            theLabelName = theLabel;
        end
        
        for iSess = 1:nSess
            
            % session and subject code
            thisSess = sessList{iSess};
            if isempty(opts.overlay)
                subjCode = fs_subjcode(thisSess);
            else
                subjCode = thisSess;
            end
            
            % waitbar
            if showWaitbar
                waitPerc = ((iLabel-1)*nSess*nAna + (iAna-1)*nSess + iSess-1) / (nLabel*nSess*nAna);
                waitMsg = sprintf('Label: %s   nTheLabel: %d   SubjCode: %s \n%0.2f%% finished...', ...
                    strrep(theLabelName, '_', '\_'), nTheLabel, strrep(subjCode, '_', '\_'), waitPerc*100);
                waitbar(waitPerc, waitHandle, waitMsg);
            end
            
            % the target subject [whose coordinates will be used
            trgSubj = fs_trgsubj(subjCode, fs_2template(thisAna, '', 'self'));
            
            % generate the overlapy to display
            if startsWith(thisAna, 'labeloverlay')
                tempNVtx = size(fs_readsurf([thisHemi '.inflated'], trgSubj), 1);
                sigFile = zeros(tempNVtx, 1);
                tempLabelMat = fs_readlabel(theLabel, subjCode);
                sigFile(tempLabelMat(:, 1)) = tempLabelMat(:, 5);
            elseif startsWith(thisAna, 'nooverlay')
                tempNVtx = size(fs_readsurf([thisHemi '.inflated'], trgSubj), 1);
                sigFile = zeros(tempNVtx, 1);
            elseif startsWith(thisAna, 'custom') && ~isempty(opts.overlay)
                sigFile = opts.overlay;
            else
                % full path to the to-be-printed file
                sigFile = fullfile(opts.funcdir, thisSess, 'bold', thisAna, thisCon, opts.sigfn);
            end
            
            % read data
            thisSurf = fs_cvn_valstruct(sigFile, thisHemi);
            nVtx = numel(thisSurf.data);
            
            % set colormap limit based on the data if necessary
            if isempty(clim)
                theunique = sort(unique(thisSurf.data(:)))';
                thisclim0 = theunique([1, end]);
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
                cmap = fm_heatscale(fmin, fmax);
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
                roicolor = opts.roicolors(1:nTheLabel, :);
                
                % mark the peak in the label
                tempLabelT = fs_labelinfo(theseLabel, subjCode, ...
                    'bycluster', 1, 'fmin', fmin);
                peakRoi = arrayfun(@(x) makeroi(nVtx, x), tempLabelT.VtxMax, 'uni', false);
                if opts.showpeak
                    rois = [thisRoi; peakRoi];
                    roicolor = repmat(roicolor, 2, 1);
                elseif opts.peakonly
                    rois = peakRoi;
                else
                    rois = thisRoi;
                end
            end
            
            % create parts of the output filename
            theLabelNames = theseLabel(~isEmptyMat);
            if all(isEmptyMat); theLabelNames = {theLabelName}; end
            labelNames = sprintf(['%s' repmat(' || %s', 1, nTheLabel-1)], theLabelNames{:});
            
            % process the extra setting for printing
            thisExtraopts = [{'cmap',cmap, 'clim', thisclim0}, opts.cvnopts];
            
            % whether display the overlay
            if ~opts.dispsig
                thisSurf.data = zeros(size(thisSurf.data));
            end
            
            %% Make the image
            %%%%%%% make image for this file %%%%%%%%
            [rawimg, lookup, rgbimg, himg] = fs_cvn_lookup(trgSubj, viewpt, thisSurf, opts.lookup, ...
                'cvnopts', thisExtraopts, ...
                'wantfig', opts.wantfig, ...
                'thresh', thresh0, ...
                'roimask', rois, ...
                'roicolor', roicolor, ...
                'roiwidth', repmat({1}, numel(rois), 1), ...
                'annot', opts.annot);
            
            if opts.drawroi
                if nargout == 0
                    assignin('base','rawimg',rawimg);
                    assignin('base','lookup',lookup);
                    assignin('base','rgbimg',rgbimg);
                    assignin('base','himg',himg);
                else
                    varargout{1} = rawimg;
                    varargout{2} = lookup;
                    varargout{3} = rgbimg;
                    varargout{4} = himg;
                end
                if showWaitbar; close(waitHandle); end
                return;
            end
            
            % clear lookup if necessary
            if ~strcmp(trgSubj, 'fsaverage')
                lookup = [];
            end
            
            %% Save the image
            close all;
            % set the figure name and save it
            fig = figure('Visible', 'off');
            imshow(rgbimg); % display lookup results (imagesc + colorbar)
            
            % obtain the contrast name as the figure name
            imgName = sprintf('%s%s || %s%s', maskStr, labelNames, thisSess, imgNameExtra);
            if length(imgName) > 200; imgName = imgName(end-200:end); end
            set(fig, 'Name', imgName);
            
            % Load and show the (first) label related information
            labelCell = cellfun(@(x) fs_labelinfo(x, subjCode, ...
                'bycluster', 1, 'fmin', fmin, 'gminfo', opts.gminfo), ...
                theLabelNames, 'uni', false);
            labelTable = vertcat(labelCell{:});
            labelTable.Properties.VariableNames{3} = 'No';
            labelTable.SubjCode = [];
            labelTable.fmin = [];
            disp(labelTable);
            
            if opts.showinfo || opts.shortinfo && ~all(isEmptyMat)
                pos = get(fig, 'Position'); %// gives x left, y bottom, width, height
                switch viewpt
                    case 3
                        pos4Extra = 2000;
                    case {'ffa'}
                        pos4Extra = pos(4);
                    otherwise
                        pos4Extra = max(ceil(pos(4)/pos(3)*1000)-100, 400);
                end
                set(fig, 'Position', [pos(1:2) max(1150, pos(3)) pos(4)+pos4Extra]);
                
                % get the short version if needed
                if opts.shortinfo
                    coorStr = {'MNI305', 'MNI305_gm'};
                    isCoorStr = ismember(coorStr, labelTable.Properties.VariableNames);
                    labelTable = labelTable(:, {'Label', coorStr{find(isCoorStr, 1, 'last')}, 'Size', 'NVtxs'}); %#ok<NASGU>
                end
                
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
            
            if opts.dispcolorbar
                colormap(cmap);
                c = colorbar;
                caxis(thisclim0);
                c.Ticks = ceil(thisclim0(1)):1:floor(thisclim0(2));
                c.TickLength = 0.02;
            end
            
            % print the figure
            subfolders = {'', subjCode, theLabel};
            
            thisOut = fullfile(outPath, subfolders{opts.subfolder+1}, [imgName '.' opts.imgext]);
            fm_mkdir(fileparts(thisOut));
            
            try
                % https://github.com/altmany/export_fig
                export_fig(thisOut, ['-' opts.imgext],'-transparent','-m2');
            catch
                print(fig, thisOut, ['-d' opts.imgext]);
            end
            
            if opts.visualimg
                set(fig, 'Visible', 'on');
            else
                close(fig);
            end
            
            varargout{1} = rawimg;
            varargout{2} = lookup;
            varargout{3} = rgbimg;
            varargout{4} = himg;
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