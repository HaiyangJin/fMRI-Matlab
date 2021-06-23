function vtxIdx = fs_readgm(subjCode, gmFn)
% vtxIdx = fs_readgm(subjCode, gmFn)
%
% This function reads the global maximal file (*.gm).
%
% Inputs:
%    subjCode        <string> subject code in $SUBJECTS_DIR.
%    gmFn            <string> gloal maximal filename.
%
% Output:
%    vtxIdx          <integer> the vertex index (in Matlab).
%
% Created by Haiyang Jin (22-June-2021)

gmFile = fullfile(getenv('SUBJECTS_DIR'), subjCode, 'label', gmFn);

if ~isfile(gmFile) % ~exist(gmFile, 'file')
    warning('Cannot find the gm file...');
    vtxIdx = NaN;
else
    
    vtxIdx = str2double(fs_readtext(gmFile));
end

end
