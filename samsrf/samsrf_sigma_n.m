function samsrf_sigma_n(srfFname, rowidx)
% samsrf_sigma_n(srfFname, rowidx)
%
% Calculate SigmaN with sigma / sqrt(Exponent) when Css/Non-linearity is
% used in pRF fitting.
%
% Inputs:
%     srfFname          <str> the file name of a Srf file.
%     rowidx            <int> which row to save SigmaN, default to the next
%                        empty row. 
%
% Created by Haiyang Jin (2023-July-11)

load(srfFname, 'Srf', 'Model');

% skip if this is not a CSS model
if ~ismember(Srf.Values, 'Exponent'); return; end

if ~exist('rowidx', 'var') || isempty(rowidx)
    rowidx = size(Srf.Data, 1) + 1;
end

% calculate Sigma / sqrt(Exponent)
Srf.Data(rowidx,:) = Srf.Data(strcmp(Srf.Values, 'Sigma'),:) ./ sqrt(Srf.Data(strcmp(Srf.Values, 'Exponent'),:));
% conver NaN to 0
Srf.Data(rowidx,isnan(Srf.Data(rowidx,:)))=0;
% add the variable name
Srf.Values(rowidx,1) = {'Sigma1'};

% save the file
save(srfFname, 'Srf', 'Model', '-v7.3');

end