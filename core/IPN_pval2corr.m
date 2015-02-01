%% Computes the correlation value given a p-value.
function r0 = IPN_pval2corr(p, numSamp, numComp)
%
% 	r0 = IPN_pval2corr(p,numSamp, numComp) computes the value of r giving P(|r| <= r0) = p
%			where r is the sample correlation coeff,
% 			r=(1/numSamp)*(x'*y)/(std(x)*std(y)) for col vectors x,y of
% 			length numSamp
% numSamp = no. samples used
% p = probability in expression above
% numComp = no. comparisons used (BF correction)
%
% USAGE: to get a r_0 so that P(|r| > r_0) = .01 use r_0 =IPN_pval2corr(1-.01,numSamp, numComp)
%
% AUTHOR: XiNian.Zuo@nyumc.org

if nargin < 3
    numComp = 1;
end
if numSamp < 3
   disp('sample size is too small');
   r0 = 1;
   return;
end
if p==1
   r0 = 1;	% all the values must be <= 1
else
   q =(1 - p)/numComp; % q is the total tail with BF correction
   t_q = tinv(1 - q/2, numSamp - 2); % P(t <= t_p) = 1-p/2 ; 1-p/2 in lower tail
   t_q = abs(t_q); %  
   r0 = t_q / (sqrt(t_q * t_q + numSamp - 2)); 
end