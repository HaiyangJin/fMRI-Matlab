function out = fs_readnifti(niiFilename, dataOnly)
% out = fs_loadnifti(niiFilename, dataOnly)
%
% This function load nifti file created by FreeSurfer. It is built based on
% FreeSurfer Matlab function (load_nifti).
% If need to rearrange the dimention of the data, use shiftdim(data,3).
%
% Inputs:
%    niiFilename       <string> the full filename of the nifti file.
%    dataOnly          <numeric> 1: only output the data but not the
%                       headers [the output will be a numeric array];
%                       0: output all the information including the deaders
%                       [the output will be a structure]; 2: only output
%                       the headers [the output will be a structure].
%
% Output:
%    out               <numeric array> when dataOnly is 1;
%                      <structure> when dataOnly is 0 or 2.
%
% Dependency:
%    FreeSurfer Matlab functions.
%
% Created by Haiyang Jin (6-April-2020)

if nargin < 2 || isempty(dataOnly)
    dataOnly = 1;
end

% make sure the file exists
assert(logical(exist(niiFilename, 'file')), 'Cannot find the file (%s).', niiFilename);

switch dataOnly
    case 0 
        % output all infromation
        out = load_nifti(niiFilename);
    case 1 
        % only output the data
        outtemp = load_nifti(niiFilename);
        out = squeeze(outtemp.vol); 
    case 2
        % only output headers
        out = load_nifti(niiFilename, 1);
end

end