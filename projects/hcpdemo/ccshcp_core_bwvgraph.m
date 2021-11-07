function [bwvgraph, bwposmat, bwnegmat, corr_thr, bwvgraph_full] = ccshcp_core_bwvgraph(boldts_lh, boldts_rh, ...
    idxBlocks_lh, idxBlocks_rh, edge_density, if_fullmat)
%CCSHCP_CORE_BWVGRAPH Perform block-wise vertex-based brain graph (bwvgraph) derived
%   using a fast block-matrix computation and sparse matrix theory.
% Inputs:
%   boldts_lh -- bold time series on the left hemisphere (surface)
%   boldts_rh -- bold time series on the right hemisphere (surface)
%   idxBlocks_lh -- predefined blocks on the left hemisphere (surface)
%   idxBlocks_rh -- predefined blocks on the right hemisphere (surface)
%   edge_density -- edge density of the final graph (surface)
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
%      Website: http://lfcd.psych.ac.cn
% Timelines:
%   2016/04/07 -- Created and tested the first version.

numBlocks_lh = numel(idxBlocks_lh); numBlocks_rh = numel(idxBlocks_lh);
if numBlocks_lh==numBlocks_rh
%% Block-wise computation
    numBlocks = numBlocks_lh;
    % reorder time series
    tmpboldts = [boldts_lh; boldts_rh]; boldts_blocks = cell(numBlocks,1);
    for netid=1:numBlocks
        boldts_blocks{netid} = tmpboldts([idxBlocks_lh{netid}; ...
        idxBlocks_rh{netid}],:);
    end
    clear tmpboldts boldts_lh boldts_rh
    blockmat = cell(numBlocks,numBlocks); centers = -1:0.001:1; 
	bwposmat = zeros(numBlocks,numBlocks); 
    bwnegmat = zeros(numBlocks,numBlocks);
    number_edges = zeros(size(centers));
    %compute full corr matrix block-wise
    for netidII=1:numBlocks
        for netidJJ=1:netidII
            disp(['block (' num2str(netidII) ',' num2str(netidJJ) ')'])
            tmpcorr = ccshcp_core_fastcorr(boldts_blocks{netidII}', ...
                boldts_blocks{netidJJ}');
            tmpTRI = tril(tmpcorr, -1); tmpNNZ = tmpTRI(tmpTRI~=0);
            number_edges = number_edges + hist(tmpNNZ(:), centers);
            bwposmat(netidII, netidJJ) = mean(atanh(tmpNNZ(tmpNNZ>0)));
            bwnegmat(netidII, netidJJ) = mean(atanh(tmpNNZ(tmpNNZ<0)));
            blockmat{netidII, netidJJ} = single(tmpcorr);
        end
    end
    if if_fullmat
       bwvgraph_full = cell2mat(blockmat);
    end
    % thresh correlation matrix
    cdf_edges = cumsum(number_edges)/sum(number_edges);
    idx_corr_thr = find(cdf_edges >= (1-edge_density)); % with 1% edge density
    corr_thr = centers(idx_corr_thr(1));
    for netidII=1:numBlocks
        for netidJJ=1:netidII
            disp(['block (' num2str(netidII) ',' num2str(netidJJ) ')'])
            tmpcorr = cell2mat(blockmat(netidII, netidJJ));
            tmpcorr(tmpcorr<corr_thr) = 0;
            blockmat{netidII, netidJJ} = sparse(double(tmpcorr));
            blockmat{netidJJ, netidII} = sparse(double(tmpcorr))';
        end
    end
    bwvgraph = cell2mat(blockmat);
end

