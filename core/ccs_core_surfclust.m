function [surfsig_clust, surfclust_pos, surfclust_neg] = ccs_core_surfclust(surfsig, nrbs, thr)
%CCS_CORE_SURFCLUST Detect clusters on the surface structure
%
% INPUT
%   surf_sig -- an N*1 vector of statistical significances of N vertices
%   nrbs -- a cell of indicating the neighbours of each vertex on the surface
%   thr -- a threshold of the cluster size (default is 19, i.e., two-step
%          neighbours)
% OUTPUT
%   surfsig_clust -- clusted maps showing significance with the threshold
%                    of the cluster size
%   surfclust_pos -- clusters showing positive significance
%   surfclust_neg -- clusters showing negative significance
%
% Author: Xi-Nian Zuo at IPCAS, Sept 27, 2016.

surfsig_clust = zeros(size(surfsig));
if nargin < 3
    thr = 19;
end
%positive clusters
surfsig_pos = sort(surfsig(surfsig>0),'descend');
%numel(surfsig_pos)%debug
surfclust_pos = [];
if ~isempty(surfsig_pos)
    tmppeak = find(surfsig==surfsig_pos(1));
    tmpclust_orig = tmppeak; 
    tmpsurfsig = surfsig_pos(2:end);
    nclust_pos = 1; surfclust_pos = [];
    while ~isempty(tmpsurfsig)
        tmpclust_update = tmpclust_orig;
        numVTX = numel(tmpclust_orig);
        for idvtx=1:numVTX
            tmpnbidx = nrbs{tmpclust_orig(idvtx)};
            for idxNBR=1:numel(tmpnbidx)
                tmpnbsig = surfsig(tmpnbidx(idxNBR));
                if tmpnbsig>0
                    tmpclust_update = [tmpclust_update; tmpnbidx(idxNBR)];
                    tmpsurfsig = setdiff(tmpsurfsig,tmpnbsig);
                end
            end
        end
        tmpclust_update = unique(tmpclust_update);
        if isempty(setdiff(tmpclust_update,tmpclust_orig))
            surfclust_pos{nclust_pos} = tmpclust_update;
            nclust_pos = nclust_pos + 1;
            tmpsurfsig = sort(tmpsurfsig,'descend');
            tmppeak = find(surfsig==tmpsurfsig(1));
            tmpclust_orig = tmppeak;
            tmpsurfsig = tmpsurfsig(2:end);
        else
            tmpclust_orig = tmpclust_update;
        end
    end
end
%negative clusters
surfsig_neg = sort(surfsig(surfsig<0),'ascend');
%numel(surfsig_neg)%debug
surfclust_neg = [];
if ~isempty(surfsig_neg)
    tmppeak = find(surfsig==surfsig_neg(1));
    tmpclust_orig = tmppeak; 
    tmpsurfsig = surfsig_neg(2:end);
    nclust_neg = 1; surfclust_neg = [];
    while ~isempty(tmpsurfsig)
        tmpclust_update = tmpclust_orig;
        numVTX = numel(tmpclust_orig);
        for idvtx=1:numVTX
            tmpnbidx = nrbs{tmpclust_orig(idvtx)};
            for idxNBR=1:numel(tmpnbidx)
                tmpnbsig = surfsig(tmpnbidx(idxNBR));
                if tmpnbsig<0
                    tmpclust_update = [tmpclust_update; tmpnbidx(idxNBR)];
                    tmpsurfsig = setdiff(tmpsurfsig,tmpnbsig);
                end
            end
        end
        tmpclust_update = unique(tmpclust_update);
        if isempty(setdiff(tmpclust_update,tmpclust_orig))
            surfclust_neg{nclust_neg} = tmpclust_update;
            nclust_neg = nclust_neg + 1;
            tmpsurfsig = sort(tmpsurfsig,'ascend');
            tmppeak = find(surfsig==tmpsurfsig(1));
            tmpclust_orig = tmppeak;
            tmpsurfsig = tmpsurfsig(2:end);
        else
            tmpclust_orig = tmpclust_update;
        end
    end
end
%sorting - pos
if ~isempty(surfclust_pos)
    numClustPos = numel(surfclust_pos);
    clustsize_pos = zeros(numClustPos,1);
    for idxClust=1:numClustPos
        tmpIDX = surfclust_pos{idxClust};
        tmpSize = numel(tmpIDX);
        if tmpSize>=thr
            surfsig_clust(tmpIDX) = surfsig(tmpIDX);
        end
        clustsize_pos(idxClust) = tmpSize;
    end
    %sum(clustsize_pos)%debug
    [~,idxSize] = sort(clustsize_pos, 'descend');
    tmpclust = surfclust_pos;
    for idxClust=1:numClustPos
        surfclust_pos{idxClust} = tmpclust{idxSize(idxClust)};
    end
end
%sorting - neg
if ~isempty(surfclust_neg)
    numClustNeg = numel(surfclust_neg);
    clustsize_neg = zeros(numClustNeg,1);
    for idxClust=1:numClustNeg
        tmpIDX = surfclust_neg{idxClust};
        tmpSize = numel(tmpIDX);
        if tmpSize>=thr
            surfsig_clust(tmpIDX) = surfsig(tmpIDX);
        end
        clustsize_neg(idxClust) = tmpSize;
    end
    %sum(clustsize_neg)%debug
    [~,idxSize] = sort(clustsize_neg, 'descend');
    tmpclust = surfclust_neg;
    for idxClust=1:numClustNeg
        surfclust_neg{idxClust} = tmpclust{idxSize(idxClust)};
    end
end    
%end of the function
end

