function [bmatrix, r] = IPN_gretna_R2b (Rmatrix, type, thr, connType)

% *************************************************************************
% [bmatrix,r] = gretna_R2b(Rmatrix, type, thr)
%
% This function is used to threshold a correlation matrix into a binary
% matrix. Here, the thresholding can be selected in 3 different ways:
%
% 1) correlation threshold. For example, when selecting a correlation
% threshold of 0.3, the elements whose absolute values are larger than 0.3
% in the correlation matrix "Rmatrix" would be substitute for 1, otherwise
% 0.
% 
%           [bmatrix,r] = gretna_R2b(Rmatrix, 'r', 0.3)
%
% 2) sparsity threshold. For example, when selecting a sparsity threshold
% of 0.1, the resulting binary matrix would have a sparsity of 0.1. Here
% the sparisty was defined as the number of edges divided by the maximum
% possible number of edges in a graph. It is noted that the elements whose
% values are "1" in the resulting binary matrix correspond to the top
% (0.1*N(N-1)/2) higher correlation values in the correlation matrix
% "Rmatrix". 
% 
%           [bmatrix,r] = gretna_R2b(Rmatrix, 's', 0.1)
%
% 3) edge threshold. For example, when selecting a edge threshold of 200,
% the resulting binary matrix would have 200 edges. It is noted that the
% edges in the resulting binary matrix correspond to the top (0.1*N(N-1)/2)
% higher correlation values in the correlation matrix "Rmatrix". 
% 
%           [bmatrix,r] = gretna_R2b(Rmatrix, 'k', 200)
%
% input:
%       Rmatrix:
%                   Rmatrix: symmetric correlation matrix.
%       type: 
%                   'r': correlation threshold; thr: the correlation value;
%                   's': sparsity threshold; thr: the sparsity value; 'k':
%                   edge threshold; thr: the number of edges;
% 
% output:
%       bmatrix: 
%                   The resulting binary matrix after thresholding the
%                   correlation matrix, "Rmatrix".
%                 r: 
%                   The corresponding correlation value at a sparsity
%                   or edge threshold. 
%
%
% Yong HE, BIC,MNI, McGill 2006/09/12
% *************************************************************************

N_region = length(Rmatrix);

%############# Changed by xinian.zuo@nyumc.org ############################
if nargin < 4
    connType = 'positive' ;
end
switch connType
    case 'positive'
         
    case 'negative'
        Rmatrix = -Rmatrix ;
    case 'both'
        Rmatrix = abs(Rmatrix) ;
    otherwise
        disp('Hi, Please give correct types of connectivity: positive, negative or both ...')
end
%############# Changed by xinian.zuo@nyumc.org ############################

Rmatrix = Rmatrix - diag(diag(Rmatrix)); % removing the self-correlation
bmatrix = zeros(size(Rmatrix));

if type == 's', % sparsity threshold
    if thr>1 | thr <=0
        error('0<thr <=1');
    end
    sparsity = thr;
    K = round(sparsity*(N_region)*(N_region-1)/2);
end

if type == 'k', %  edge threshold, i.e. the number of edges
    if thr <1 | thr >= (N_region)*(N_region-1)/2,
        error(' 1<=thr<N*(N-1)/2');
    end
    K = thr;
end

if type == 's' | type == 'k',
    R_matrixretmp1 = reshape(Rmatrix, N_region*N_region,1);
    [R_matrixrer1 R_matrixreindex1] = sort(R_matrixretmp1);
    R_matrixretmp1(R_matrixreindex1(1:(end-2*K))) = 0;
    r = R_matrixretmp1(R_matrixreindex1((end-2*K+1)));
%     R_matrixretmp1(R_matrixreindex1((end-(2*K-1)):end)) = 1;
%     bmatrix = reshape(R_matrixretmp1,N_region,N_region);
%-------------------------------------------------------   
% edited by liang 29/05/09
    if r == 0
        bmatrix = Rmatrix > r; % edited by liang 29/05/09
        bmatrix = bmatrix-diag(diag(bmatrix));
    else
        bmatrix = Rmatrix >= r;
        bmatrix = bmatrix-diag(diag(bmatrix));
    end
end


if type == 'r' % correlation threshold
    bmatrix(Rmatrix >= thr) =1;
    r  = nnz(bmatrix)/(N_region*(N_region-1)); %Xi-Nian edited.
end

