%% IPN_GoogleRank is a modification of the PageRank algorithm (i.e., personalised page rank).
function r = IPN_centPagerank(W, d, falff)
%% function r = IPN_pageRank(W, d, falff)
% 
% INPUTS:   
%       W - adjacent  matrix (sparse matrix with one/zero, zero diag)
%       d - parameter in algorithm (surfer probability)
%   falff - vector of lfo amplitude levels (non-negative)
%
% OUTPUTS:
%       r - vectors of page rankings
% USAGE:
%   W = [0 0 0 1 0 1;
%        1 0 0 0 0 0;
%        0 1 0 0 0 0;
%        0 1 1 0 0 0;
%        0 0 1 0 0 0;
%        1 0 1 0 0 0;]
%   r = IPN_pageRank(W, 0.85);
% Of note, the answer should be
%   [0.321016940895182,0.170543038221924,0.106591629585789,...
%    0.136792591301763,0.0643118000574449,0.200743999937897]
%
% REFERENCE: 
%   [1]. GeneRank: Using search engine technology for the analysis of microarray experiments,       
%            by Julie L. Morrison, Rainer Breitling, Desmond J. Higham and David R. Gilbert, 
%            BMC Bioinformatics, 6:233, 2005.
% 	[2]. An Inner-Outer iteration for computing pagerank,
%            by Gleich DF, Gray AP, Greif C, Lau T. 
%            SIAM J Sci Comput, 32: 349-371, 2010.
% REQUIRMENT:
%   Please install Inner-Outer toolbox first from
%       http://www.stanford.edu/~dgleich/publications/2009/innout
%
% AUTHOR:
%   Xi-Nian Zuo, Ph.D. of Applied Mathematics
%   Institute of Psychology, Chinese Academy of Sciences.
%   Email: ZuoXN@psych.ac.cn
%   Website: lfcd.psych.ac.cn

nvoxels = size(W, 1);
if nargin < 3
    norm_falff = ones(nvoxels, 1)/nvoxels;
else
    falff = abs(falff);
    norm_falff = falff/sum(falff);
end
d = 0.85;
tol = 1e-10;
%positive connectivity
W = sparse(W);
if nvoxels > 1000
    P = normout(W);
    r = feval('inoutpr',P,d,[],tol);
else
    deg = full(sum(W));
    ind = (deg == 0);
    deg(ind) = 1;
    D1 = sparse(1:nvoxels, 1:nvoxels, 1./deg, nvoxels, nvoxels);
    clear deg
    A = speye(nvoxels, nvoxels) - d*(W*D1);
    b = (1-d)*norm_falff;
    r = A\b; r = r/sum(r);
end