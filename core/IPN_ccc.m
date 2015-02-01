%% Computes the concordance correlation coefficient for evaluating reproducibility.
function rc = IPN_ccc(Y)
% INPUT:
%   Y - a N*R data matrix
%
% REFERENCE:
%   Lin, L.I. 1989. A Corcordance Correlation Coefficient to Evaluate
%   Reproducibility. Biometrics 45, 255-268.
%
% XINIAN ZUO 2008
% zuoxinian@gmail.com

Ybar = mean(Y);S = cov(Y,1);R = size(Y,2);
tmp = triu(S,1);
rc = 2*sum(tmp(:))/((R-1)*trace(S)+IPN_ssd(Ybar));
