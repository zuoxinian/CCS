%% Computes the eta-suqare between two vectors.
function eta = IPN_etaSquare(X, Y)
%
% Inputs:
%   X - vector 1
%   Y - vector 2
% Xi-Nian.Zuo@nyumc.org

a = reshape(X, numel(X), 1);
b = reshape(Y, numel(Y), 1);
m = (a + b) / 2; mbar = mean(m);
SSw = sum((a - m).^2 + (b - m).^2);
SSt = sum((a - mbar).^2 + (b - mbar).^2);
eta = 1 - SSw / SSt;