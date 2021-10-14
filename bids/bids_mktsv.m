function bids_mktsv(content, fn, bidsDir)
% bids_mktsv(content, fn, bidsDir)
%
% Make *.tsv file for BIDS. It may create participant_id.tsv or *.tsv for 
% events. The participant_id.tsv may need further manual modification.
%
% Inputs:
%    content        <table> table will be saved as *.tsv directly.
%                OR <cell> a list of subject codes.
%                OR <str> wildcard strings to match subject codes. Default 
%                    is 'sub-*'. 
%    fn             <str> output filename (without extension). 
%    bidsDir        <str> the BIDS directory. Default is bids_dir().
%
% Output:
%    Save an *.tsv file (e.g., participant_id.tsv).
%   
% Created by Haiyang Jin (2021-10-13)

if ~exist('bidsDir', 'var') || isempty(bidsDir)
    bidsDir = bids_dir();
end

if ~exist('content', 'var') || isempty(content)
    content = 'sub-*';
end

if ~exist('fn', 'var') || isempty(fn)
    fn = 'participants';
end
if ~endsWith(fn, '.txt'); fn = [fn '.txt']; end

% Deal with the content
if iscell(content)
    participant_id = content;

elseif ischar(content)
    % find all subject folders
    participant_id = bids_subjlist(content)'; 
end

% convert to table
if istable(content)
    T = content;
else
    T = table(participant_id);
end

% save as txt first
txtfn = fullfile(bidsDir, fn);
writetable(T, txtfn, 'Delimiter','\t')

% update it as tsv
movefile(txtfn, strrep(fullfile(bidsDir, fn), '.txt', '.tsv'));

end
