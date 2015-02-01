%% Convert a T-value to a Z-value
function z = IPN_statT2Z(t,df)
% df: degree of freedom, n-1 for one-sample t-tests. Note: only for one-sample or correlation. 
% Xi-Nian Zuo
r = t./sqrt(df + t.*t);
z = sqrt(df - 1).*atanh(r);