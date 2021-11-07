function Pn = ccs_core_graphnbtw(A,n)
%CCS_CORE_GRAPHNBTW Number of non-backtracking walks on an undirected graph
%   Inputs:
%     A - adjacency matrix
%     n - walk distance
%   Outputs:
%     Pn - matrix indexing numbers of non-backtracking walks on the graph A
% Copyright:
%   Xi-Nian Zuo codes this function in 11/20/2019, Seattle, Washington.
%   This is part of the Connectome Computation System (CCS)
%   Website: https://github.com/zuoxinian/CCS ; https://climbgroup.org
%   
% References:
%   [1] Arrigo et al., 2018, Linear Algebra and its Applications, 556:
%   381-399.
%   [2] Xu et al., 2015, Science Bulletin, 60(1): 86-95.

if issymmetric(A)
    A = sparse(A - diag(diag(A)));
    D = sparse(diag(diag(A^2)));
    if n==0
        Pn = spyeye(size(A)); 
    end
    if n==1
        Pn = A; 
    end
    if n==2
        Pn = A^2 - D;
    end
    if n>2
        %updated in 09/30/2021
        Pn1 = ccs_core_graphnbtw(A,n-2);
        Pn2 = ccs_core_graphnbtw(A,n-1);
        Pn = Pn2*A + Pn1*(speye(size(A))-D);
    end
else
    disp('Currently this function only works for undirected graphs!')
end

end