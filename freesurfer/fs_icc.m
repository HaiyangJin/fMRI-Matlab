function iccT = fs_icc(sessList, anaList, labelList, varargin)
% iccT = fs_icc(sessList, anaList, labelList, contraList, varargin)
%
% Calculates ICC(3, 1) for multiple fMRI sessions.
%
% Multiple fMRI session data could be organized in two ways:
% (1) Different fMRI sessions are saved as different FreeSurfer sessions
%     (e.g., 'Subj01_sess01' and 'Subj01_sess02' in $FUNCTIONALS_DIR; each
%     session has several runs);
% (2) Different fMRI sessions of the same participant are saved as one
%     FreeSurfer session (e.g., 'Subj01' in $FUNCTIONALS_DIR). Within this
%     session folder, differernt run files (e.g., 'loc_sess1.txt' which saves
%     the run names in the first session) are used to indicate the runs from
%     different fMRI sessions. [Recommended]
%
% Inputs:
%    sessList     <cell str> PxQ. P is the number of participant no matter
%                  how many sessions each participant has. If sessions are
%                  organized with the first approach, Q is the number of
%                  sessions each participant has. If sessions are organized
%                  with the second approach, Q is 1.
%    anaList      <cell str> MxN. M is the number of ICC to be computed.
%                  If sessions are organized with the first approach, N is
%                  1, which is the analysis to be computed. If sessions are
%                  organized with the second approach, N is the number of
%                  measurements/analyses to be used to compute ICC.
%    labelList    <cell str> a list of label files. If it is empty
%                  (default), ICC for all vertices will be computed. If it
%                  is not empty, only vertices in the label will be used to
%                  calculate the ICC.
%
% Varargin:
%
% %%%% for ICC %%%%
%     .type, .alpha, .r0    in-arguments for ICC. see help fule for
%     stat_icc().
%
%
% Output:
%
% Created by Haiyang Jin (2022-Jan-06)

defaultOpts = struct(...
    'runwise', 0, ...
    'datafn', 'beta.nii.gz', ...
    'type', 'C-1', ...
    'alpha', [], ...
    'r0', []);
opts = fm_mergestruct(defaultOpts, varargin);

% some maybe nonsense default
if ischar(sessList); sessList = {sessList}; end
if ischar(anaList); anaList = {anaList}; end

nLabel = numel(labelList);
[nSess, nSessM] = size(sessList); % P x Q
[nICC, nAnaM] = size(anaList);    % M x N
assert(ismember(nSessM * nAnaM, [nSessM, nAnaM]), ['Either the second ' ...
    'dimention of sessList (%d) or anaList (%d) has to be 1.'], ...
    nSessM, nAnaM);

%% Calculate ICC for each pair/group
icc_out = cell(nSess, nICC, nLabel);
tmp_icc = struct;

for iSess = 1:nSess
    
    % for each session (pair/group)
    theSess = sessList(iSess,:);
    tmp_icc.Session = theSess(:)';

    for iICC = 1:nICC

        theAna = anaList(iICC,:);
        tmp_icc.Analysis = theAna(:)';

        for iLabel = 1:nLabel

            tmp_icc.Labelfn = labelList{iLabel};

            % load data for multiple sessions/measurement
            opts.labelfn = labelList{iLabel};
            ds = fs_cosmo_sessdsmulti(theSess, theAna, opts);

            % all conditions in the ds
            conditions = unique(ds.sa.labels);

            icc_con_cell = cell(length(conditions), 1);

            % compute ICC for each condition separately
            for iCon = 1:numel(conditions)

                tmp = tmp_icc;
                tmp.Condition = conditions(iCon);

                ds_con = cosmo_slice(ds, cosmo_match(ds.sa.labels, conditions(iCon)));

                [tmp.r, tmp.LB, tmp.UB, tmp.F, tmp.df1, tmp.df2, tmp.p] =  ...
                    stat_icc(ds_con.samples', opts.type, opts.alpha, opts.r0);


                icc_con_cell{iCon, 1} = tmp;
            end % iCon

            icc_out{iSess, iICC, iLabel} = vertcat(icc_con_cell{:});

        end % iLabel
    end % iICC
end % iSess

iccT = vertcat(icc_out{:});

end