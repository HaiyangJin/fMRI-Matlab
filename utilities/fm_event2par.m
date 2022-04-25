function fm_event2par(eventfile, parfile, condOrder, fixaName, weights)
% fm_event2par(eventfile, parfile, condOrder, fixaName, weights)
%
% Converts event tsv files in bids to par files used in FreeSurfer.
% 
% Inputs:
%    eventfile     <str> the full path to the bids event tsv file.
%    parfile       <str> the full path to the par file in FS-FAST.
%    conOrder      <cell str> the condition orders. The default is sorting
%                   by alphabeta order with fixation condition being the
%                   first.
%    fixaName      <str> name of the fixation condition. Default is
%                   'fixation'. 
%    weights       <num vec> weights of each row. Default is all 1.
%
% Output:
%    converted par files.
%
% Created by Haiyang Jin (2022-April-25)

if nargin < 1
    fprintf('Usage: fm_event2par(eventfile, parfile, condOrder, fixaName, weights);\n');
    return;
end

% read the tsv file
tsvcontent = tdfread(eventfile);

% condition names
trial_type = cellstr(tsvcontent.trial_type);

% condition order
if ~exist('condOrder', 'var') || isempty(condOrder)
    condOrder = unique(trial_type);
end

% force Fixation to be the first 
if ~exist('fixaName', 'var') || isempty(fixaName)
    fixaName = 'fixation';
end
condOrder(strcmp(condOrder, fixaName))=[];
condOrder = vertcat(fixaName, condOrder);

% condition identifier
Identifier = cellfun(@(x) find(strcmp(x, condOrder)), trial_type)-1;

if ~exist('weights', 'var') || isempty(weights)
    weights = ones(numel(Identifier),1);
end
Weight = weights;

% create the par file table
parTable = table(tsvcontent.onset, Identifier, tsvcontent.duration, ...
    Weight, trial_type);

% try to save the par files
try
    % try to create par file with fm_mkfile
    fm_mkfile(parfile, table2cell(parTable));

catch
    % if failed, use writetable and rename the file
    tempText = strrep(parfile, '.par', '.txt');
    writetable(parTable, tempText, 'Delimiter', ' ', 'WriteVariableNames', false);
    % rename the file
    movefile(tempText, parfile);
end

end
