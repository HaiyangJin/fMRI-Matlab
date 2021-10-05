function hcp_setup(wbPath)
% hcp_setup(wbPath)
%
% Add workbench path to $PATH.
%
% Input:
%    wbPath          <str> path to the workbench.
%
% Created by Haiyang Jin (2021-10-05)

if ~exist('wbPath', 'var') || isempty(wbPath)
    if ismac % for Mac
        wbPath = '/Applications/workbench/bin_macosx64';
    elseif isunix % for linux
        wbPath = '/usr/local/workbench';
    else
        error('Platform not supported.');
    end
end

setenv('PATH', sprintf('%s:%s', wbPath, getenv('PATH'))); % add wb path to PATH

end