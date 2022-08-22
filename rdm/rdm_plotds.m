function rdm_plotds(ds, varargin)
% rdm_plotds(ds, varargin)
%
% Use rdm_plotrdm() to plot RDM vectors in ds. 
%
% Inputs:
%     ds       <struct> RDM dataset.
%     
% Varargin:
%     Please see Varargin in rdm_plotrdm().
%
% Created by Haiyang Jin (2022-Aug-22)

if nargin < 1
    fprintf('Usage: rdm_plotds(ds, varargin);\n');
end

% convert ds.samples to RDM (matrix from vector)
rdms = rdm_vec2rdm(ds.samples, 0.5);

% plot
rdm_plotrdm(rdms, 'condnames', ds.a.conditions, 'titles', ds.fa.labels, varargin{:});

end