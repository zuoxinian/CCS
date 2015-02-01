function [pID,pN] = IPN_FDR(p,q)
% FORMAT pt = FDR(p,q)
% 
% p   - vector of p-values
% q   - False Discovery Rate level
%
% pID - p-value threshold based on independence or positive dependence
% pN  - Nonparametric p-value threshold
%______________________________________________________________________________
% @(#)FDR.m	1.3 Tom Nichols 02/01/18


p = sort(p(:));
V = length(p);
I = (1:V)';

cVID = 1;
cVN = sum(1./(1:V));

pID = p(max(find(p<=I/V*q/cVID)));
pN = p(max(find(p<=I/V*q/cVN)));

