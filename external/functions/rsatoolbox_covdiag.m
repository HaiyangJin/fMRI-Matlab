function [sigma,shrinkage,sample]=covdiag(x,df,varargin)
% function [sigma,shrinkage]=covdiag(x,df)
% Regularises the estimate of the covariance matrix accroding to the 
% optimal shrikage method as outline in Ledoit& Wolf (2005). 
% Shrinks towards diagonal matrix
% INPUT: 
%       x     (t*n): t observations on p random variables
%       df    (1*1): optional: degrees of freedom, if not t-1 
% OUTPUT: 
%       sigma (n*n): invertible covariance matrix estimator
%       shrinkage  : Applied shrinkage factor 
% 

% Note by Haiyang:
% This function was copied from
% https://brunel.figshare.com/articles/dataset/Faces_and_voices_in_the_brain_dataset/6429200/1
% which is originally (and slightly modified) from 
% https://github.com/rsagroup/rsatoolbox_matlab/blob/develop/%2Brsa/%2Bstat/covdiag.m 

Opt.shrinkage = []; 
%Opt = rsa.getUserOptions(varargin,Opt);

% de-mean returns
[t,n]=size(x);
x=bsxfun(@minus,x,sum(x)./t);  % Subtract mean of each time series fast  

% compute sample covariance matrix
if nargin<2 || isempty(df) 
    df=t-1; 
end; 

% Compute sample covariance matrix
sample=(1/df).*(x'*x);

% compute prior
prior=diag(diag(sample));

% if required, compute shrinkage parameter using Ledoit-Wolf method 
if (isempty(Opt.shrinkage))
    d=1/n*norm(sample-prior,'fro')^2;
    y=x.^2;
    r2=1/n/df^2*sum(sum(y'*y))-1/n/df*sum(sum(sample.^2));
    shrinkage = max(0,min(1,r2/d));
else 
    shrinkage = Opt.shrinkage; 
end; 

% Regularize the estimate
sigma=shrinkage*prior+(1-shrinkage)*sample;

