function   ec = IPN_centEigenvector(CIJ)
% HISTORY:
%   Ross Ehmke provided the initial version of the script. 
%   Xi-Nian Zuo edited in 09/09/2010.
% INPUTS:
%   CIJ - Connection matrix:
%         all positive connections,
%         high value <-> high connectivity
%         low  value <-> low  connectivity
% OUTPUTS:
%   ec - eigenvector centrality (EC)
% AUTHOR:
%   Xi-Nian Zuo, Ph.D. of Applied Mathematics
%   Institute of Psychology, Chinese Academy of Sciences.
%   Email: ZuoXN@psych.ac.cn
%   Website: lfcd.psych.ac.cn

n = length(CIJ) ;
if n < 1000
    [V,~] = eig(CIJ) ;
    ec = abs(V(:,n)) ; % Make it no matter of including diag 1/0 by using ABS.
else
    [V, ~] = eigs(sparse(CIJ)) ;
    ec = abs(V(:,1)) ;
end
ec = double(reshape(ec, length(ec), 1));