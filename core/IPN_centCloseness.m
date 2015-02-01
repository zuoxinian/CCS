function cc = IPN_centCloseness(CIJ, type)
%Xi-Nian Zuo: based on BCT
% Here the CIJ is the correlation or similarity matrix.
% Note: only for undirected graph
switch type
    case 0
        D = distance_bin(CIJ); % use BCT function
        D = 2.^(-D);
        cc = sum(D - diag(diag(D))); 
        cc = reshape(cc, length(cc), 1);
    case 1
        % Here the weights for edges should be a distance measure between two
        % nodes, for example, 1./corr or 1 - corr.
        idx = find(CIJ); CIJ(idx) = 1./CIJ(idx);
        D = distance_wei(CIJ); % use BCT function
        D = 2.^(-D);
        cc = sum(D - diag(diag(D))); 
        cc = reshape(cc, length(cc), 1);
    otherwise
        disp('Need type of networks: binarized or weighted.')
end