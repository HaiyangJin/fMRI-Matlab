function fp_mktsv(content, fn, bidsDir)
%fp_mktsv(content, fn, bidsDir)
%
% Make *.tsv file. Mainly used to make participant_id.tsv here. These files
% needs further manual modification.
%
% Inputs:
%    content        <table> table will be saved as *.tsv directly.
%                OR <cell> a list of subject codes.
%                OR <str> wildcard strings to match subject codes. Default 
%                    is 'sub-*'. 
%    fn             <str> output filename (without extension). 
%    bidsDir        <str> the BIDS directory. Default is fp_bidsdir.
%
% Output:
%    Save an *.tsv file (e.g., participant_id.tsv).
%   
% Created by Haiyang Jin (2021-10-13)

if ~exist('bidsDir', 'var') || isempty(bidsDir)
    bidsDir = fp_bidsdir;
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
    participant_id = fp_subjlist(content); 
end

% convert to table
if istable(content)
    T = content;
else
    sex = repmat({'n/a'}, size(participant_id));
    age = repmat({'n/a'}, size(participant_id));
    T = table(participant_id, sex, age);
end

% save as txt first
txtfn = fullfile(bidsDir, fn);
writetable(T, txtfn, 'Delimiter','\t')

% update it as tsv
movefile(txtfn, strrep(fullfile(bidsDir, fn), '.txt', '.tsv'));

end
