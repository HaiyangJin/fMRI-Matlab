function fs_cvn_print1st(sessList, anaList, labelList, sigFn, thresh, outPath, extraopts, funcPath)
% fs_cvn_print1st(sessList, anaList, labelList, [sigFn='sig.nii.gz', thresh=1.301i...
%    outPath=[pwd'/First_level_results'], extraopts={}, funcPath])
%
% This function prints the first-level results and the labels in label/.
%
% Inputs:
%    sessList        <cell string> list of session codes (in funcPath).
%    anaList         <cell string> list of analysis names.
%    labelList       <cell string> list of label names or list of contrast
%                     names.
%    sigFn           <string> name of the to-be-printed file [Default is
%                     sig.nii.gz].
%    thresh0         <numeric> display threshold. overlayalpha =
%                     ,val>threshold. Only show activation within the
%                     threshold.
%    outPath         <string> where to save the output images. [current
%                     folder by default].
%    extraopts       extra options for cvnlookupimages.m.
%    funcPath        <string> the path to functional folder [Default is
%                     $FUNCTIONALS_DIR].
%
% Output:
%    images of first-level analysis results.
%
% Created by Haiyang Jin (20-Apr-2020)

% waitbar
waitHandle = waitbar(0, 'Preparing for printing first-level results...');

%% Deal with intputs
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

if ~exist('sigFn', 'var') || isempty(sigFn)
    sigFn = 'sig.nii.gz';
end
if ~exist('thresh', 'var') || isempty(thresh)
    thresh = 1.3010i;  % 0.05
end
% output path
if ~exist('outPath', 'var') || isempty(outPath)
    outPath = fullfile(pwd, 'First_level_results');
end
outPath = fullfile(outPath, sigFn);

if ~exist('extraopts', 'var') || isempty(extraopts)
    extraopts = {};
end

if ~exist('funcPath', 'var') || isempty(funcPath)
    funcPath = getenv('FUNCTIONALS_DIR');
end

% generate settings
clim0 = [];
cmap0 = jet(256);  % use jet(256) as the colormap
lookup = [];
wantfig = 2;  % do not show figure with fs_cvn_lookuplmv.m

nLabel = numel(labelList);
nSess = numel(sessList);

%% For each label
for iLabel = 1:nLabel
    
    thisLabel = labelList{iLabel};
    
    % the contrast and the hemi information
    thisCon = fs_2contrast(thisLabel);
    thisHemi = fs_2hemi(thisLabel);
    
    % threshold for plotting
    thresh0 = fs_2sig(thisLabel)/10 * 1i;
    if isempty(thresh0); thresh0 = thresh; end
    
    % identify the cooresponding analysis name
    theseAna = endsWith(anaList, thisHemi);
    theAnaList = anaList(theseAna);
    nAna = numel(theAnaList);
    
    for iAna = 1:nAna
        
        thisAna = theAnaList{iAna};
        % update thisHemi based on the analysis name
        thisHemi = fs_2hemi(thisAna);
        
        for iSess = 1:nSess
            
            % session and subject code
            thisSess = sessList{iSess};
            subjCode = fs_subjcode(thisSess, funcPath);
            
            % waitbar
            progress = ((iLabel-1) * nSess + iSess-1) / (nLabel * nSess);
            waitMsg = sprintf('Label: %s    SubjCode: %s \n%0.2f%% finished...', ...
                strrep(thisLabel, '_', '\_'), strrep(subjCode, '_', '\_'), progress*100);
            waitbar(progress, waitHandle, waitMsg);
            
            % template and the target subject [whose coordinates will be
            % used]
            template = fs_2template(thisAna);
            trgSubj = fs_trgsubj(subjCode, template);
            
            % full path to the to-be-printed file
            sigFile = fullfile(funcPath, thisSess, 'bold', thisAna, thisCon, sigFn);
            
            % read data
            thisSurf = fs_cvn_valstruct(sigFile, thisHemi);
            
            % set colormap limit based on the data if necessary
            if isempty(clim0)
                thisclim0 = prctile(thisSurf.data(:),[1 99]);
            else
                thisclim0 = clim0;
            end
            
            % read the label
            thisMat = fs_readlabel(subjCode,thisLabel);
            
            % initialize a mask including all vertices
            thisRoi = zeros(size(thisSurf.data));
            maskStr = 'NoLabel || ';
            
            if ~isempty(thisMat)
                maskStr = '';
                % create binary masks
                thisRoi(thisMat(:, 1)) = 1;
            elseif ~endsWith(thisLabel, '.label')
                maskStr = '';
            end
            
            % process the setting for printing
            thisExtraopts = [extraopts, {'cmap',cmap0, 'clim', thisclim0, ...
                'roimask',thisRoi, 'roicolor',[1, 1, 1], 'roiwidth', 1}];
            
            %%%%%%% make image for this file %%%%%%%%
            [lookup, rgbimg] = fs_cvn_lookup(trgSubj, 2, thisSurf, ...
                thresh0, lookup, wantfig, thisExtraopts);
            
            % clear lookup if necessary
            if ~strcmp(trgSubj, 'fsaverage')
                lookup = [];
            end
            
            %% Save the image
            % set the figure name and save it
            fig = figure('Visible','off');
            imshow(rgbimg); % display lookup results (imagesc + colorbar)
            
            % obtain the contrast name as the figure name
            imgName = sprintf('%s%s || %s', maskStr, thisLabel, thisSess);
            set(fig, 'Name', imgName);
            
            colorbar;
            colormap(cmap0);
            caxis(thisclim0);
            
            % print the figure
            theOutPath = fullfile(outPath, thisLabel);
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