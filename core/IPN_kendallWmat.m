%% Computes the pair-wise Kendall's W for each pair of columns in a matrix.
function [W,p,Fdist]=IPN_kendallWmat(X,tied)
% X is a n*k ratings matrix.
% n is the number of objects and k is the number of judges.
% Author: Xi-Nian Zuo (xinian.zuo@nyumc.org)

[~,k]=size(X);
W = zeros(k,k);
p = zeros(k,k);
Fdist = zeros(k,k);
for r=1:k
    rates_r = X(:,r);
    for c=r:k
        rates_c = X(:,c);
        [W(r,c) p(r, c) Fdist(r, c)] = IPN_kendallW([rates_r rates_c],tied);
    end
end
