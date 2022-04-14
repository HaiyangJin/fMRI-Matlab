function [cmdout, isnotok] = bids_validator(bidsDir, runcmd)
% [cmdout, isnotok] = bids_validator(bidsDir, runcmd)
% 
% Use docker to run bids validator. 
%
% Inputs:
%    bidsDir           <str> the BIDS directory. Default is bids_dir().
%    runcmd            <boo> whether to run the cmd.
%
% Output:
%    cmdout            <cell> the first column is the cmd and the second 
%                       column is whether the cmd is run without error (0).
%    isnotok           <vec> whether the cmd were run without error.
%    
% Created by Haiyang Jin (2022-April-14)

if ~exist('bidsDir', 'var') || isempty(bidsDir)
    bidsDir = bids_dir();
end

if ~exist('runcmd', 'var') || isempty(runcmd)
    runcmd = 1;
end

% cmd for bids validator
cmd = sprintf('docker run -ti --rm -v %s:/data:ro bids/validator /data', bidsDir);

[cmdout, isnotok] = fm_runcmd(cmd, runcmd);

end