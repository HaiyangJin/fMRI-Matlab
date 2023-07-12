function prfFnList = fs_samsrf_listprfs(prf_wc)
% prfFnList = fs_samsrf_listprfs(prf_wc)
%
% Inputs:
%     prf_wc      <cell str> wildcard to identify the pRF file(s). If prf_wc 
%                  contains '=vs=', the strings will be split by '=vs=' and
%                  the differnt strings will be used to identify pRF files,
%                  which will be put in one cell together. In this case, 
%                  `prfFnList` is a cell of cell (otherwise it is a cell str). 
%
% Output:
%     prfFnList   <cell> a list of pRF files or a list of a list of pRF
%                   files.
%
% Created by Haiyang Jin (2023-July-01)

% ensure a cell
if ischar(prf_wc); prf_wc = {prf_wc}; end

% idenity pRF files for each wildcard
prfFnCell = cellfun(@list_prffiles, prf_wc, 'uni', false);
prfFnList = vertcat(prfFnCell{:});

end



%% Local function
function prfFnList = list_prffiles(prf_wc)

if ~contains(prf_wc, '=vs=')

    % identify all matched files
    prfdir = dir(prf_wc);
    % only keep files starting with 'lh' or 'rh'
    prfdir(cellfun(@(x) ~startsWith(x, {'lh', 'rh'}), {prfdir.name})) = [];
    assert(~isempty(prfdir), 'Cannot idenitify any pRF files...');

    % each cell is one pRF file
    prfFnList = fullfile({prfdir.folder}, {prfdir.name});

else
    % split the filename by '=vs='
    [keypath, keyfn, keyext] = fileparts(prf_wc);
    keys = strsplit([keyfn, keyext], '=vs=');

    % find all files matching `keys{1}`
    key1dir = dir(fullfile(keypath, ['*' keys{1} '*']));
    assert(~isempty(key1dir), 'Cannot identify any files...');

    % only keep files starting with 'lh' or 'rh'
    key1dir(cellfun(@(x) ~startsWith(x, {'lh', 'rh'}), {key1dir.name})) = [];
    key1list = fullfile({key1dir.folder}, {key1dir.name})';

    % initialize the output 
    prfFnList = cell(length(key1list), 1);
    for i = 1:length(key1dir)

        assert(contains(key1list{i}, keys{1}), ['Cannot find the char (%s) ' ...
            'in the base pRF file name (%s)...'], keys{1}, key1list{i});
        % find files matching other keys
        keyslist = cellfun(@(x) strrep(key1list{i}, keys{1}, x), keys(2:end), 'uni', false);
        % ensure the file exist
        keyslist(cellfun(@(x) exist(x, 'file')~=2, keyslist)) = [];

        % put files matched the keys together
        prfFnList{i, 1} = horzcat(key1list(i), keyslist);

    end
    % each cell in prfFnList is a group of pRF files, which will be plotted
    % together

end

% ensure a column vec cell
prfFnList = prfFnList(:);

end
