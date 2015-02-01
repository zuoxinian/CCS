function [ R p Xadj Yadj] = LFCD_corr_covar( X, Y, Z)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

[~, p1] = size(X);
[~, p2] = size(Y);
R = zeros(p1, p2); p = R; 
Xadj = zeros(size(X)) ; Yadj = zeros(size(Y));
Z_demean = IPN_demean(Z);
for m=1:p1
    [~, ~, x] = regress(X(:,m), Z_demean);
    Xadj(:,m) = x;
    for n=1:p2
        [~, ~, y] = regress(Y(:,n), Z_demean);
        [R(m,n), p(m,n)] = corr(x, y);
        if m==1
            Yadj(:,n) = y;
        end
    end
end

