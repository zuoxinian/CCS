function [p_adj,t_adj] = ccs_ttest2_bayesadj(y,x,xhist)
%CCS_TTEST2_BAYESADJ Adjust T stats for two-sample t-tests using Bayesian
%   INPUT:
%       x - healthy control
%       y - clinical condition
%       xhist - historical samples of healthy control

n0 = numel(xhist);
n = numel(x);
u0 = mean(xhist);
u = mean(x);
S0 = var(xhist);
S = var(x);
starV = n0 + n;
starW = (n0/n0+n)*S0 + (n-1)/(n0+n)*S + (n*n0)/((n0+n)^2)*(u0-u)^2;
adjSGM = sqrt(n0/(starV-2))*starW;
t_adj = (mean(y)-u)/(sqrt(1/n+1/numel(y))*adjSGM);
p_adj = 1 - tcdf(abs(t_adj),n+numel(y)-2);

end

