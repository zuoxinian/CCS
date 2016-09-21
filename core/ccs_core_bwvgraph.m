function [bwvgraph, bwposmat, bwnegmat, corr_thr, bwvgraph_full] = ccs_core_bwvgraph(boldts, idxBlocks, ...
    edge_density, if_fullmat)
%CCS_CORE_BWVGRAPH Perform block-wise vertex-based brain graph (bwvgraph) derived
%   using a fast block-matrix computation and sparse matrix theory.
% Inputs:
%   boldts -- bold time series (matrix)
%   idxBlocks -- predefined blocks (cell of vectors)
%   edge_density -- edge density of the final graph
%   if_fullmat -- if output the full version of the graph
% Outputs:
%   bwvgraph -- final threshed brain graph
%   bwposmat -- block-wise connection matrix derived using mean vertex-wise
%               positive correlation
%   bwnegmat -- block-wise connection matrix derived using mean vertex-wise
%               negative correlation
%   corr_thr -- correlation threshold corresponding to the edge_density
%   bwvgraph_full -- unthreshed brain graph
%
% Credits:
%      Xi-Nian Zuo, PhD of Applied Mathematics
%      Institue of Psychology, Chinese Academy of Sciences.
%      Email: zuoxn@psych.ac.cn or zuoxinian@gmail.com
%      Website: http://zuolab.psych.ac.cn
% Timelines:
%   2016/04/07 -- Created and tested the first version.

numBlocks = numel(idxBlocks_lh);
%% Block-wise computation
    % reorder time series
    boldts_blocks = cell(numBlocks,1);
    for blkid=1:numBlocks
        boldts_blocks{blkid} = boldts(idxBlocks{blkid},:);
    end
    clear boldts
    blockmat = cell(numBlocks,numBlocks); centers = -1:0.001:1; 
	bwposmat = zeros(numBlocks,numBlocks); 
    bwnegmat = zeros(numBlocks,numBlocks);
    number_edges = zeros(size(centers));
    %compute full corr matrix block-wise
    for blkidII=1:numBlocks
        for blkidJJ=1:blkidII
            disp(['block (' num2str(blkidII) ',' num2str(blkidJJ) ')'])
            tmpcorr = ccs_core_fastCoRR(boldts_blocks{blkidII}', ...
                boldts_blocks{blkidJJ}');
            tmpTRI = tril(tmpcorr, -1); tmpNNZ = tmpTRI(tmpTRI~=0);
            number_edges = number_edges + hist(tmpNNZ(:), centers);
            bwposmat(blkidII, blkidJJ) = mean(atanh(tmpNNZ(tmpNNZ>0)));
            bwnegmat(blkidII, blkidJJ) = mean(atanh(tmpNNZ(tmpNNZ<0)));
            blockmat{blkidII, blkidJJ} = single(tmpcorr);
        end
    end
    if if_fullmat
       bwvgraph_full = cell2mat(blockmat);
    end
    % thresh correlation matrix
    cdf_edges = cumsum(number_edges)/sum(number_edges);
    idx_corr_thr = find(cdf_edges >= (1-edge_density)); % with 1% edge density
    corr_thr = centers(idx_corr_thr(1));
    for blkidII=1:numBlocks
        for blkidJJ=1:blkidII
            disp(['block (' num2str(blkidII) ',' num2str(blkidJJ) ')'])
            tmpcorr = cell2mat(blockmat(blkidII, blkidJJ));
            tmpcorr(tmpcorr<corr_thr) = 0;
            blockmat{blkidII, blkidJJ} = sparse(double(tmpcorr));
            blockmat{blkidJJ, blkidII} = sparse(double(tmpcorr))';
        end
    end
    bwvgraph = cell2mat(blockmat);
end

