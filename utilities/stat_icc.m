function [r, LB, UB, F, df1, df2, p] = stat_icc(M, type, alpha, r0)
% [r, LB, UB, F, df1, df2, p] = stat_icc(M, type, alpha, r0)
%
% Calculates the Intraclass correlation coefficient with ICC(), which is
% available at https://www.mathworks.com/matlabcentral/fileexchange/22099-intraclass-correlation-coefficient-icc
%
% Inputs:
%    M        <mat> each row is a Target; each column is a Judge. In fMRI,
%              each row is one feature (voxel/vertex) and each column is
%              one measurement (session/run). Default is the example data
%              from Shrout & Fleiss (1979).
%    type     <str> default is 'C-1', which is used for calculating the
%              fMRI reliability. More see help document for ICC().
%    alpha, r0  -> please check the help document for ICC().
%
% Outputs:
%    r        <num> the estimated intraclass correlation.
%    LB       <num> the lower bound of the ICC with alpha level of
%              significance.
%    UB       <num> the upper bound of the ICC with alpha level of
%              significance.
%    F, df1, df2 <num> parameters estimated during ICC calculation.
%    p        <num> the p-value.
%
% % Examples:
% ICC([], '1-1') % ICC(1, 1)
% ICC([], '1-k') % ICC(1, 4)
% ICC([], 'C-1') % ICC(3, 1) % default
% ICC([], 'C-k') % ICC(3, 4)
% ICC([], 'A-1') % ICC(2, 1)
% ICC([], 'A-k') % ICC(2, 4)
%
% References:
% Shrout, P. E., & Fleiss, J. L. (1979). Intraclass correlations: Uses in
%   assessing rater reliability. Psychological Bulletin, 86(2), 420–428.
%   https://doi.org/10.1037/0033-2909.86.2.420
% McGraw, K. O., & Wong, S. P. (1996). Forming inferences about some
%   intraclass correlation coefficients. Psychological Methods, 1(1),
%   30–46. https://doi.org/10.1037/1082-989X.1.1.30
%
% Created by Haiyang Jin (2021-11-30)

if ~exist('M', 'var') || isempty(M)
    % % This example data are from Shrout & Fleiss (1979).
    M = [9 2 5 8;
        6 1 3 2;
        8 4 6 8;
        7 1 2 6;
        10 5 6 9;
        6 2 4 7];
    warning('The example data from Shrout & Fleiss (1979) is used.')
end

if ~exist('type', 'var') || isempty(type)
    type = 'C-1'; % the method typically used to measure fMRI reliability
end

if ~exist('alpha', 'var') || isempty(alpha)
    alpha = 0.05; % its default in ICC()
end

if ~exist('r0', 'var') || isempty(r0)
    r0 = 0; % its default in ICC()
end

[r, LB, UB, F, df1, df2, p] = ICC(M, type, alpha, r0);

end