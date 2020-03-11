function fs_savemgz(subjCode, surfData, outputFn, structPath, outputPath)
% fs_savemgz(subjCode, surfData, outputFn, structPath, outputPath)
% 
% This function is built based on nsd_savemgz.m created by Kendrick Kay 
% (https://github.com/kendrickkay/nsdcode/). 
%
% This function saves the surface data as MGZ file or MGH file
% (uncompressed).
%
% Inputs:
%     subjCode         <string> subject code in SUBJECTS_DIR.
%     surfData         <array of numeric> nVtx * D (where D >= 1) [Data to 
%                      be saved].
%     outputFn         <string> filename of the output file (without path) 
%                      [the filename must conform to the format
%                      [lh,rh].XXX.[mgz,mgh].
%     structPath       <string> 'SUBJECTS_DIR' in FreeSurfer.
%
% Output:
%     a new *.mgz or *.mgh file will be saved at subjects/surf/
%
% Dependency:
%     FreeSurfer Matlab codes...
%
% Created by Haiyang Jin (19-Jan-2020)

if nargin < 4 || isempty(structPath)
    structPath = getenv('SUBJECTS_DIR');
end
if nargin < 5 || isempty(outputPath)
    outputPath = fullfile(structPath, subjCode, 'surf');
end

if ~ismember({'.mgh', '.mgz'}, outputFn(end-3:end))
    outputFn = [outputFn, '.mgz'];
end

% obtain hemi information from outputFn
hemi = fs_hemi(outputFn);

% load tempalte 
thisSubjPath = fullfile(structPath, subjCode);
if strcmp(subjCode, 'fsaverage')
    template = sprintf('%s/surf/%s.orig.avg.area.mgh',thisSubjPath,hemi);
else
    template = sprintf('%s/surf/%s.w-g.pct.mgh',thisSubjPath,hemi);
end
fsmgh = MRIread(template);

% information of surface data to be saved
[nVtx, nD] = size(surfData);
% sanity check
if nVtx==1
  error('<surfData> should have surface data oriented along the columns');
end

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