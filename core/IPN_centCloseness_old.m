function Q = IPN_centCloseness(CIJ)
%Xi-Nian Zuo: based on matlab_bgl toolbox
% Here the weights for edges should be a distance measure between two
% nodes, for example, 1./corr or 1 - corr.

D = all_shortest_paths(sparse(CIJ)) ;
B = sum(D) ;
n = length(CIJ) ;
E = B/(n-1) ;
Q = 1./E ;