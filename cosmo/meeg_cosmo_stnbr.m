function spat_time_nbrhood = meeg_cosmo_stnbr(ds, surfs, timeLabel, varargin)
% spat_time_nbrhood = meeg_cosmo_stnbr(ds, surfs, timeLabel, varargin)
%
% This function performs searchlight for meeg data for both spatial
% (channels or sources) and timepoints at the same time. 
%
% Inputs:
%    dt            <structure> data structure used in CoSMoMVPA.
%    surfs         surfs used in cosmo_surficial_neighborhood. If surfs is
%                   '', searchlight will not be performed on .source. 
%    timeLabel     <string> dimension label in ds.a.fdim.labels. 
%
% Varargin:
%    .source       vararing used in cosmo_surficial_neighborhood. Default 
%                   is struct([]).
%    .chan         varargin used in cosmo_meeg_chan_neighborhood. Default
%                   is struct([]). 
%    .time         varargin used in cosmo_interval_neighborhood. Default is
%                   struct([]).
%
% Output:
%    spat_time_nbrhood <struct> neighborhood structure.
% 
% Created by Haiyang Jin (1-Jan-2021)

defaultOpts = struct();
defaultOpts.source = struct([]);
defaultOpts.chan = struct([]);
defaultOpts.time = struct([]);

opts = fm_mergestruct(defaultOpts, varargin(:));

% At least one of .source, .chan, and .time has to be defined. Note only 
% one of .source or .chan can be used in the one analysis. 

% space neighborhoods
if  ~isempty(surfs) && ~isempty(opts.source)
    
    % source neighborhood (surficial)
    spat_nbrhood=cosmo_surficial_neighborhood(ds,surfs,opts.source);
    
elseif ~isempty(opts.chan)
    % channel neighborood
    spat_nbrhood=cosmo_meeg_chan_neighborhood(ds, opts.chan);
end

% time neighborhoods
time_nbrhood=cosmo_interval_neighborhood(ds, timeLabel, opts.time);

% cross neighborhood
spat_time_nbrhood=cosmo_cross_neighborhood(ds, {spat_nbrhood,time_nbrhood});

end