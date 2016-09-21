%% Computes large correlation-based adjacent matrix (LCAM).
function [R_short, R_long] = ccs_core_distdpdtLCAM(data, corrthresh, distthresh, distmat, nblock, connType)
% INPUTS:
%   data   - the sample data: n*p size;
%   corrthresh - the thresh to decide the adjacency;
%   distthresh - the threshhold of anatomical distance;
%   distmat - distance matrix
%   nblock - the number of blocks in the data;
%   connType - the type of functional connectivity;
% OUTPUTS:
%   R_short - short-distance weighted adjacent matrix;
%   R_long - long-distance weighted adjacent matrix;
% AUTHOR:
%   Xi-Nian Zuo, Ph.D. of Applied Mathematics
%   Institute of Psychology, Chinese Academy of Sciences.
%   Email: ZuoXN@psych.ac.cn
%   Website: zuolab.psych.ac.cn

[~, p] = size(data);
if nargin < 5
    nblock = 1;
    connType = 'positive';    
end
if nargin < 6
    connType = 'positive';
end
data = double(data); %make sure of enough storage
R_short = sparse([],[],[],p,p,0);
R_long = sparse([],[],[],p,p,0);
cols_end = rem(p, nblock);
size_block = fix(p / nblock);
%block process
for m=1:nblock
    display(['the ' num2str(m), '-th block ...'])
    start_dim = (m-1)*size_block;
    end_dim = m*size_block;
    idx_block = (start_dim+1):end_dim;
    data_block = data(:,idx_block);
    r_block = ccs_core_fastCoRR(data_block, data);
    clear data_block
    dist_block = distmat(idx_block,:);
    switch connType
        case 'positive'
            idx = find(r_block >= corrthresh);
        case 'negative'
            idx = find((-r_block) >= corrthresh);
        case 'abs'
            idx = find(abs(r_block) >= corrthresh);
    end
    %short distance connection
    idx_short = intersect(idx, find(dist_block < distthresh)); clear dist_block
    r_block_sthr = r_block(idx_short);
    s = reshape(r_block_sthr, length(idx_short), 1); clear r_block_sthr
    [I,J] = ind2sub([size_block, p],idx_short);
    R_short = R_short + sparse(start_dim + I, J, s, p, p);
    %long distance connection
    idx_long = setdiff(idx, idx_short);
    r_block_lthr = r_block(idx_long);
    s = reshape(r_block_lthr, length(idx_long), 1); clear r_block_lthr
    [I,J] = ind2sub([size_block, p],idx_long);
    R_long = R_long + sparse(start_dim + I, J, s, p, p);
    clear s r_block
end
if cols_end ~= 0
    %the last block
    display(['the ' num2str(nblock+1), '-th block ...'])
    idx_block = (nblock*size_block+1):p;
    data_block = data(:,idx_block);
    r_block = ccs_core_fastCoRR(data_block, data);
    clear data_block
    dist_block = distmat(idx_block,:);
    switch connType
        case 'positive'
            idx = find(r_block >= corrthresh);
        case 'negative'
            idx = find((-r_block) >= corrthresh);
        case 'abs'
            idx = find(abs(r_block) >= corrthresh);
    end
    %short distance connection
    idx_short = intersect(idx, find(dist_block < distthresh)); clear dist_block
    r_block_sthr = r_block(idx_short);
    s = reshape(r_block_sthr, length(idx_short), 1) ; clear r_block_sthr
    [I,J] = ind2sub([p-nblock*size_block, p],idx_short);
    R_short = R_short + sparse(nblock*size_block+I, J, s, p, p);
    %long distance connection
    idx_long = setdiff(idx, idx_short);
    r_block_lthr = r_block(idx_long);
    s = reshape(r_block_lthr, length(idx_long), 1) ; clear r_block_lthr
    [I,J] = ind2sub([p-nblock*size_block, p],idx_long);
    R_long = R_long + sparse(nblock*size_block+I, J, s, p, p);
    clear s r_block distmat
end
R_short = R_short - sparse(1:p, 1:p, spdiags(R_short,0), p, p, p);
R_long = R_long - sparse(1:p, 1:p, spdiags(R_long,0), p, p, p);

