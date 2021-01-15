function fs_savemgz(subjCode, surfData, outputFn, outputPath, hemi, structPath)
% fs_savemgz(subjCode, surfData, outputFn, outputPath, hemi, structPath)
%
% This function is built based on nsd_savemgz.m created by Kendrick Kay
% (https://github.com/kendrickkay/nsdcode/).
%
% This function saves the surface data as MGZ file or MGH file
% (uncompressed).
%
% Inputs:
%    subjCode         <string> subject code in SUBJECTS_DIR.
%    surfData         <array of numeric> nVtx * D (where D >= 1) [Data to
%                      be saved].
%    outputFn         <string> filename of the output file (without path)
%                      [the filename must conform to the format
%                      [lh,rh].XXX.[mgz,mgh].
%    outputPath       <string> where the *.mgz file will be saved.
%    structPath       <string> 'SUBJECTS_DIR' in FreeSurfer.
%
% Output:
%    a new *.mgz or *.mgh file will be saved in outputPath.
%
% Dependency:
%     FreeSurfer Matlab codes...
%
% Created by Haiyang Jin (19-Jan-2020)

if nargin < 4 || isempty(outputPath)
    outputPath = fullfile(structPath, subjCode, 'surf');
end

if nargin < 5 || isempty(hemi)
    % obtain hemi information from outputFn
    hemi = fs_2hemi(outputFn);
end
assert(ismember(hemi, {'lh', 'rh'}), ...
    '''hemi'' can only be ''lh'' or ''rh'' (not %s)', hemi);

if nargin < 6 || isempty(structPath)
    structPath = getenv('SUBJECTS_DIR');
end

if ~ismember({'.mgh', '.mgz'}, outputFn(end-3:end))
    outputFn = [outputFn, '.mgz'];
end

% load tempalte
thisSubjPath = fullfile(structPath, subjCode);
if strcmp(subjCode, 'fsaverage')
    template = sprintf('%s/surf/%s.orig.avg.area.mgh',thisSubjPath,hemi);
else
    template = sprintf('%s/surf/%s.w-g.pct.mgh',thisSubjPath,hemi);
end
fsmgh = MRIread(template);

% information of surface data to be saved
if size(surfData, 2) > 1; surfData = surfData'; end
[nVtx, nD] = size(surfData);
% sanity check
assert(nVtx~=1, '<surfData> should have surface data oriented along the columns');

% mangle fields
outputFilename = fullfile(outputPath, outputFn);
fsmgh.fspec = outputFilename;
fsmgh.vol = reshape(surfData,1,nVtx,1,nD);  % 1 x V x 1 x D
fsmgh.volsize = [1 nVtx 1];
fsmgh.height = 1;
fsmgh.width = nVtx;
fsmgh.depth = 1;
fsmgh.nframes = nD;
fsmgh.nvoxels = nVtx;

% write
MRIwrite(fsmgh,outputFilename);

end