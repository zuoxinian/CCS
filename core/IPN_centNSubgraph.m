function   sc = IPN_centNSubgraph(CIJ, type)
% Computes the normalized subgraph centralities of the network
% represented by the adjacency matrix CIJ. It returns a vector of subgraph
% centralities for each node of the network (as they are ordered in the
% adjacency matrix).
%Xi-Nian Zuo edited in 10/11/2010.
%inputs
%           CIJ    connection matrix
%           all positive connections,
%           high value <-> high connectivity
%           low  value <-> low  connectivity
%           type <-> binary or weighted graph           
%           
%
%outputs
%           sc      subgraph centrality
%Note: 1. for large matrix would be very time/memory consuming, 
%      thus we only wrap in the first 6 eigenvectors.
%      2. it would not change the order of centralities whether 
%      you remove the diagnal 1s or not.
%=================================================
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
    lambda = diag(lambda/max(lambda(:)));               % eigenvalues.
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
    lambda = spdiags(lambda/max(lambda(:)));
    V2 = V.^2;
    sc = real(V2 * sinh(lambda));
    sc = reshape(sc, length(sc), 1);
end
