function   bc = IPN_centBetweenness(CIJ, type)
%Xi-Nian Zuo: based on matlab_bgl toolbox
%inputs
%           CIJ    connection matrix
%          
%
%outputs
%           bc      betweenness
%
%=================================================

switch type
    case 0
        options.unweighted = 1;
        bc = betweenness_centrality(sparse(CIJ), options) ;
    case 1
        % Here the weights for edges should be a distance measure between two
        % nodes, for example, 1./corr or 1 - corr.
        bc = betweenness_centrality(sparse(CIJ)) ;
    otherwise
        disp('Need type of networks: binarized or weighted.')
end
