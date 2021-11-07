function Wn = ccs_core_graphwalk(A,n)
%CCS_CORE_GRAPHWALK Number of walks on an undirected graph
%   Inputs:
%     A - adjacency matrix
%     n - walk distance
%   Outputs:
%     Wn - matrix indexing numbers of walks of length n on the graph A
% Copyright:
%   Xi-Nian Zuo codes this function in 03/30/2020, Seattle, Washington.
%   This is part of the Connectome Computation System (CCS)
%   Website: https://github.com/zuoxinian/CCS ; https://climbgroup.org
%   
% References:
%   [1] Arrigo et al., 2018, Linear Algebra and its Applications, 556:
%   381-399.
%   [2] Xu et al., 2015, Science Bulletin, 60(1): 86-95.

if issymmetric(A)
    A = sparse(A - diag(diag(A)));
    if n > 1
        Wpre = ccs_core_graphwalk(A,n-1);
        Wndg = Wpre - diag(diag(Wpre));
        Wn = A*Wndg;
        Wn = Wn - diag(diag(Wn));
    else
        Wn = A;
    end
else
    disp('Currently this function only works for undirected graphs!')
end

end