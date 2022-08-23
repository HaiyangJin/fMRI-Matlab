function rdm_plotds(ds, diagValue, varargin)
% rdm_plotds(ds, varargin)
%
% Use rdm_plotrdm() to plot RDM vectors in ds. 
%
% Inputs:
%     ds            <struct> RDM dataset.
%     diagValue     <num> value to be displayed on the diagnoal. Default to
%                    0. 
%     
% Varargin:
%     Please see Varargin in rdm_plotrdm().
%
% Created by Haiyang Jin (2022-Aug-22)

if nargin < 1
    fprintf('Usage: rdm_plotds(ds, varargin);\n');
end

if ~exist('diagValue', 'var') || isempty(diagValue)
    diagValue = 0;
end

% convert ds.samples to RDM (matrix from vector)
rdms = rdm_vec2rdm(ds.samples, diagValue);

% plot
rdm_plotrdm(rdms, 'condnames', ds.a.conditions, 'titles', ds.fa.labels, varargin{:});

end