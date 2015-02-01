function   sc = IPN_centSubgraph(CIJ, type)
% Computes the subgraph centralities of the network
% represented by the adjacency matrix CIJ. It returns a vector of subgraph
% centralities for each node of the network (as they are ordered in the
% adjacency matrix).
%
% INPUTS:
%   CIJ - Connection matrix:
%         all positive connections,
%         high value <-> high connectivity
%         low  value <-> low  connectivity
%   type - binary or weighted graph
%
% OUTPUTS:
%   sc - subgraph centrality (SC)
%
% NOTE: 
%   1. for large matrix would be very time/memory consuming, 
%      thus we only wrap in the first 20 eigenvectors.
%   2. it would not change the order of centralities whether 
%      you remove the diagnal 1s or not.
%
% REFERENCE:
%   [1]. Network properties revealed through matrix functions, 
%        by Estrada E, Higham DJ, 
%        SIAM Rev. 52: 696-714, 2010.
%
% AUTHOR:
%   Xi-Nian Zuo, Ph.D. of Applied Mathematics
%   Institute of Psychology, Chinese Academy of Sciences.
%   Email: ZuoXN@psych.ac.cn
%   Website: lfcd.psych.ac.cn

n = length(CIJ);
if nargin < 2
    type = 'b';
end

if n < 1000
    CIJ = CIJ + eye(n);
    switch type
        case 'b'
            [V,lambda] = eig(CIJ);                   % Compute the eigenvectors and
        case 'w'
            B = sum(CIJ)';
            C = diag(B);
            D = C^(-(1/2));
            [V,lambda] = eig(D*CIJ*D);
    end
    lambda = diag(lambda);               % eigenvalues.
    V2 = V.^2;                       % Matrix of squares of the eigenvectors elements.
    sc = real(V2 * sinh(lambda));    % Lop off imaginary part remaining due to precision error.
    sc = reshape(sc, length(sc), 1);
else
    spCIJ = sparse(CIJ);
    switch type
        case 'b'
            [V, lambda] = eigs(spCIJ, 20);
        case 'w'
            B = sum(spCIJ);
            s = full(B.^(-1/2)); % need fullly connected graph!!
            D = sparse(1:n, 1:n, s, n, n);
            [V, lambda] = eigs(D*spCIJ*D);
    end
    lambda = spdiags(lambda);
    V2 = V.^2;
    %sc = real(V2 * sinh(lambda));
    sc = n*real(V2 * ((n-1)./(n-1-lambda)));
    sc = reshape(sc, length(sc), 1);
end
