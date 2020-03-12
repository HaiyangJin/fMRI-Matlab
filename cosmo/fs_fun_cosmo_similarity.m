function predictTable = fs_fun_cosmo_similarity(project, labelList, ...
    classPairs, condName, condWeight, outputPath)
% predictTable = fs_fun_cosmo_similarity(project, labelList, ...
%     classPairs, condName, condWeight, outputPath)
%
% This function decodes the similarity of condName to classPairs for all
% the sessions in the project. libsvm is used in this analysis.
%
% Inputs:
%    project             <structure> project structure (obtained from
%                         fs_fun_projectinfo).
%    labelList           <cell of strings> a list of label names.
%    classPairs          <cell of strings> a PxQ (usually is 2) cell matrix 
%                         for the pairs to be classified. Each row is one 
%                         classfication pair. 
%    condName            <cell of strings> a PxQ cell vector for the 
%                         conditions to be combined for the similarity test.
%                         The row number should be same as that for
%                         classPairs. The similarity of condName to
%                         classPairs will be tested separated for each row.
%    condWeight          <array of numeric> a PxQ numeric array for the
%                         weights to be applied to the combination of condName.
%                         Each row of weights is tested separately.
%    output_path         <string> where output to be saved.
%
% Output:
%    predictTable        <table> the prediction for the new condition and 
%                         the related information.
%
% Dependencies:
%    FreeSurfer matlab functions;
%    CoSMoMVPA
%
% Created by Haiyang Jin (11-March-2020)

% The row numbers of classPairs and condName should be the same.
nClass = size(classPairs, 1);
assert(nClass == size(condName, 1), ...
    'The row numbers of classPairs and condName should be the same.');

if nargin < 5 || isempty(condWeight)
    condWeight = '';
elseif size(condWeight, 2) ~= size(condName, 2)
    error('The column numbers of condWeight and condName should be the same.');
end

if nargin < 6 || isempty(outputPath)
    outputPath = '';
end

%% Preparations
% waitbar
waitHandle = waitbar(0, 'Loading...   0.00% finished');

% sessions
sessList = project.sessList;
nSess = project.nSess;

% label information
if ischar(labelList)
    labelList = {labelList};
end
nLabel = numel(labelList);

%% Run cosmo_similarity
% empty cell for saving prediction table
cellTable = cell(nSess * nLabel * nClass, 1);
thisRow = 0;

for iSess = 1:nSess
    
    % this session code
    thisSess = sessList{iSess};
    info.SubjCode = {thisSess};
    
    for iLabel = 1:nLabel
        
        % this label name
        thisLabel = labelList{iLabel};
        info.Label = {thisLabel};
        
        % load the data set
        ds_this = fs_cosmo_subjds(project, thisLabel, thisSess, 'main', '', 1);
        
        % continue if the ds_this is empty
        if isempty(ds_this)
            continue;
        end

        for iClass = 1:nClass
            
            % waitbar
            progress = ((iSess-1)*nLabel*nClass + (iLabel-1)*nClass + iClass-1)...
                / (nLabel * nSess * nClass);
            progressMsg = sprintf('Subject: %s   Label: %s. \n%0.2f%% finished...', ...
                strrep(thisSess, '_', '\_'), thisLabel, progress*100);
            waitbar(progress, waitHandle, progressMsg);
            
            % the classPair and condName for this decoding
            thisClass = classPairs(iClass, :);
            thisCondName = condName(iClass, :);
            
            %%%%%%%%%%%%%%% estimate the similarity %%%%%%%%%%%%%%%%%%
            thisPredictTable = cosmo_similarity(ds_this, thisClass, thisCondName, condWeight);
            
            % add the information for this decoding
            if ~isempty(thisPredictTable)
                thisTable = horzcat(repmat(struct2table(info), size(thisPredictTable, 1), 1), thisPredictTable);
            else
                thisTable = thisPredictTable;
            end
            
            % save this prediction table
            thisRow = thisRow + 1;
            cellTable(thisRow, 1) = {thisTable};
        end
    end
end

%% Save the output
% waitbar
waitbar(progress, waitHandle, 'Saving data...');

% obtain the predictTable
predictTable = vertcat(cellTable{:});

% the path
if isempty(outputPath)
    outputPath = '.';
end
outputPath = fullfile(outputPath, 'Classification');
if ~exist(outputPath, 'dir'); mkdir(outputPath); end

% the filename
similarityFn = fullfile(outputPath, 'Main_Similarity');
save(similarityFn, 'predictTable');

writetable(predictTable, [similarityFn, '.xlsx']);
writetable(predictTable, [similarityFn, '.csv']);

% close the waitbar 
close(waitHandle); 

end