function   bc = IPN_centBetweenness(CIJ, type)
%Xi-Nian Zuo: based on BCT
%inputs
%           CIJ    connection matrix
%          
%
%outputs
%           bc      betweenness
%
% Here the CIJ is the correlation or similarity matrix.
% Note: only for undirected graph.
%=================================================

switch type
    case 0
        bc = betweenness_bin(CIJ); % use BCT function
        bc = reshape(bc, length(bc), 1);
    case 1
        % Here the weights for edges should be a distance measure between two
        % nodes, for example, 1./corr or 1 - corr.
        idx = find(CIJ); CIJ(idx) = 1./CIJ(idx);
        bc = betweenness_wei(CIJ); % use BCT function
        bc = reshape(bc, length(bc), 1);
    otherwise
        disp('Need type of networks: binarized or weighted.')
end
