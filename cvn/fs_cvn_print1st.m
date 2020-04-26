function fs_cvn_print1st(sessList, anaList, labelList, outPath, varargin)
% fs_cvn_print1st(sessList, anaList, labelList, outPath, varargin)
%
% This function prints the first-level results and the labels in label/.
%
% Inputs:
%    sessList        <cell string> list of session codes (in funcPath).
%    anaList         <cell string> list of analysis names.
%    labelList       <cell string> list of label names or list of contrast
%                     names.
%    outPath         <string> where to save the output images. [current
%                     folder by default].
%
% Optional inputs (varargin):
%    'sigFn'         <string> name of the to-be-printed file [Default is
%                     sig.nii.gz].
%    'thresh'        <numeric> display threshold. Default is 1.3010 (abs).
%    'clim'          <numeric array> limits for the color map. The Default
%                     empty, which will display responses from %1 to 99%.
%    'cmap'          <> use which color map, default is jet.
%    'annot'         <string> which annotation will be used. Default is
%                     '', i.e., not display annotation file.
%    'viewpt'        <integer> the viewpoitns to be used. More see
%                     fs_cvn_lookup.m. Default is -2.
%    'roicolors'     <numeric array> colors to be used for the label roi
%                     masks.
%    'markPeak'      <logical> mark the location of the peak response.
%                     Default is 0.
%    'showInfo'      <logical> show label information in the figure.
%                     Default is 0, i.e., do not show the label information.
%    'wantfig'       <logical/integer> Default is 2, i.e., do not show the
%                     figure. More please check fs_cvn_lookup.
%    'lookup'        <> setting used for cvnlookupimage.
%    'funcPath'      <string> the path to functional folder [Default is
%                     $FUNCTIONALS_DIR].
%
% Output:
%    images of first-level analysis results.
%
% Created by Haiyang Jin (20-Apr-2020)

% waitbar
waitHandle = waitbar(0, 'Preparing for printing first-level results...');

%% Deal with intputs

defaultOpts = struct(...
    'sigfn', 'sig.nii.gz', ...
    'thresh', 1.3010i, ...
    'viewpt', -2, ...
    'roicolors', {[1, 1, 1;  % white
    1, 1, 0;  % yellow
    1, 0, 1;  % Magenta / Fuchsia
    0, 0, 1;  % blue
    ]}, ...
    'clim', [], ...
    'cmap', jet(256), ...
    'annot', '', ...
    'lookup', [], ...
    'wantfig', 2, ...
    'cvnopts', {{}}, ...
    'showinfo', 0, ...
    'markpeak', 0, ... % mark the peak response in the label
    'funcpath', getenv('FUNCTIONALS_DIR'), ...
    'strupath', getenv('SUBJECTS_DIR'));

options = fs_mergestruct(defaultOpts, varargin);

% generate settings
viewpt = options.viewpt;
clim = options.clim;
cmap = options.cmap;  % use jet(256) as the colormap
annot = options.annot;  % the annotation file
lookup = options.lookup;
wantfig = options.wantfig;  % do not show figure with fs_cvn_lookuplmv.m
roicolors = options.roicolors;
showInfo = options.showinfo;
markPeak = options.markpeak;
cnvopts = options.cvnopts;

sigFn = options.sigfn;
thresh = options.thresh;  % 0.05
funcPath = options.funcpath;

% some maybe nonsense default
if ischar(sessList); sessList = {sessList}; end
if ~exist('anaList', 'var') || isempty(anaList)
    anaList = {'loc_sm5_self.lh', 'loc_sm5_self.rh'};
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
    if isempty(thresh0); thresh0 = thresh; end
    
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
            progress = ((iLabel-1)*nSess*nAna + (iAna-1)*nSess + iSess-1) / (nLabel*nSess*nAna);
            waitMsg = sprintf('Label: %s   nTheLabel: %d   SubjCode: %s \n%0.2f%% finished...', ...
                strrep(theLabelName, '_', '\_'), nTheLabel, strrep(subjCode, '_', '\_'), progress*100);
            waitbar(progress, waitHandle, waitMsg);
            
            % the target subject [whose coordinates will be used
            trgSubj = fs_trgsubj(subjCode, fs_2template(thisAna));
            
            % full path to the to-be-printed file
            sigFile = fullfile(funcPath, thisSess, 'bold', thisAna, thisCon, sigFn);
            
            % read data
            thisSurf = fs_cvn_valstruct(sigFile, thisHemi);
            nVtx = numel(thisSurf.data);
            
            % set colormap limit based on the data if necessary
            if isempty(clim)
                thisclim0 = prctile(thisSurf.data(:),[1 99]);
            else
                thisclim0 = clim;
            end
            
            % read the label and remove empty cells
            [thisMat, maxCell] = cellfun(@(x) fs_readlabel(x, subjCode), theseLabel, 'uni', false);
            isEmptyMat = cellfun(@isempty, thisMat);
            thisMat(isEmptyMat) = [];
            maxCell(isEmptyMat) = [];
            
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
                    rois = [thisRoi; cellfun(@(x) makeroi(nVtx, x), maxCell, 'uni', false)'];
                    roicolor = repmat(roicolor, 2, 1);
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
            
            % clear lookup if necessary
            if ~strcmp(trgSubj, 'fsaverage')
                lookup = [];
            end
            
            %% Save the image
            % set the figure name and save it
            fig = figure('Visible','off');
            imshow(rgbimg); % display lookup results (imagesc + colorbar)
            
            % obtain the contrast name as the figure name
            imgName = sprintf('%s%s || %s', maskStr, labelNames, thisSess);
            set(fig, 'Name', imgName);
            
            % Load and show the (first) label related information
            if showInfo && ~all(isEmptyMat)
                labelCell = cellfun(@(x) fs_labelinfo(x, subjCode), theLabelNames, 'uni', false);
                labelTable = struct2table(vertcat(labelCell{:}));
                labelTable.SubjCode = [];
                
                pos = get(fig, 'Position'); %// gives x left, y bottom, width, height
                set(fig, 'Position', [pos(1:2) max(1050, pos(3)) pos(4)+max(pos(4)/pos(3)*1000-600, 500)]);
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
                    'Position',[0 0 1 0.1],'FontSize',12,'LineStyle','none');
            end
            
            colorbar;
            colormap(cmap);
            caxis(thisclim0);
            
            % print the figure
            theOutPath = fullfile(outPath, theLabel);
            if ~exist(theOutPath, 'dir'); mkdir(theOutPath); end
            thisOut = fullfile(theOutPath, [imgName '.png']);
            
            try
                % https://github.com/altmany/export_fig
                export_fig(thisOut, '-png','-transparent','-m2');
            catch
                print(fig, thisOut,'-dpng');
            end
            
        end   % iSess
    end   % iAna
end   % iLabel

close(waitHandle);

end

function theroi = makeroi(nVtx, maskVtx)
% create a roi binary mask
theroi = zeros(nVtx, 1);
theroi(maskVtx) = 1;
end