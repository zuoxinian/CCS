function   ec = ccshcp_core_ec(CIJ)
%CCSHCP_CORE_EC Perform computation of the network eigenvector centrality.
% INPUTS:
%   CIJ - Connection matrix:
%         all positive connections,
%         high value <-> high connectivity
%         low  value <-> low  connectivity
% OUTPUTS:
%   ec - eigenvector centrality (EC)
% Credits:
%   Xi-Nian Zuo, Ph.D. of Applied Mathematics
%   Institute of Psychology, Chinese Academy of Sciences.
%   Email: ZuoXN@psych.ac.cn
%   Website: lfcd.psych.ac.cn
% Timelines:
%   2010/10/01 -- Created and tested the first version.
%   2016/04/07 -- Revised the codes for N < 1000 nodes.

n = length(CIJ) ;
if n < 1000
    [V,D] = eig(CIJ);
    tmpeig = diag(D); % Modified according to Jiahui's comments.
    [~, idxmax] = max(tmpeig);
    ec = abs(V(:,idxmax)); % Make it no matter of including diag 1/0 by using ABS.
else
    [V, ~] = eigs(sparse(CIJ)) ;
    ec = abs(V(:,1)) ;
end
ec = double(reshape(ec, length(ec), 1));