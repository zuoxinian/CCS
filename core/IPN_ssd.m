%% Computes the sum square distance for evaluating reproducibility.
function ssd = IPN_ssd(X)
% INPUT:
%   X - a 1*R data vector
%
% REF:
%   Lin, L.I. 1989. A Corcordance Correlation Coefficient to Evaluate
%   Reproducibility. Biometrics 45, 255-268.
%
% XINIAN ZUO 2008
% zuoxinian@gmail.com

R=length(X);ssd=0;
for k=1:R-1
    ssd=ssd+sum((X(k+1:R)-X(k)).*(X(k+1:R)-X(k)));
end