function PR = ccs_core_graphnbtw2(A,r)
%CCS_CORE_GRAPHNBTW Number of non-backtracking walks on an undirected graph
%   Inputs:
%     A - adjacency matrix
%     r - walk distance
%   Outputs:
%     PR - matrix indexing numbers of non-backtracking walks on the graph A
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
    A = A - diag(diag(A));
    D = diag(diag(A^2));
    if r==0
        PR = eye(size(A)); 
    end
    if r==1
        PR = A; 
    end
    if r==2
        PR = A^2 - D;
    end
    if r>2
        %updated in 03/27/2020
        PR1 = ccs_core_graphnbtw(A,r-2);
        PR1 = PR1 - diag(diag(PR1));
        PR2 = ccs_core_graphnbtw(A,r-1);
        PR2 = PR2 - diag(diag(PR2));
        PR = A*PR2 - (D-eye(size(A)))*PR1;
    end
else
    disp('Currently this function only works for undirected graphs!')
end

end