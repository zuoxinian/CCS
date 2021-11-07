function [ R_bin, R_wei, nvoxels, s_thr, r_thr, p ] = IPN_doSingleSubject_voxelNSubgraph( infname, maskfname, gmfname, outfprefix, p, gm_thr )
% Summary of this function goes here
%   Detailed explanation goes here
% Xinian.Zuo@nyumc.org

    if nargin < 5
        p = 0.0001;
        gm_thr = 0.20;
    end
    n_thr = length(p);
    r_thr = zeros(n_thr,1);
    s_thr = zeros(n_thr,1);
    [nii, dims] = read_avw(infname);
    n_tp = dims(4);
    lfo_res = reshape(nii, prod(dims(1:3)), n_tp);
    clear nii
    nii = read_avw(maskfname);
    mask = reshape(nii, prod(dims(1:3)), 1);
    clear nii
    nii = read_avw(gmfname);
    gm = reshape(nii, prod(dims(1:3)), 1);
    idx = find(gm.*mask > gm_thr);
    nvoxels = length(idx);
    lfo_res_gm = lfo_res(idx, :);
    clear lfo_res nii
    
    for n=1:length(r_thr)
        r_thr(n) = IPN_pval2corr(1-p(n), n_tp);
        % Compute correlation matrix
        [R_bin, R_wei] = IPN_calLCAM(lfo_res_gm', r_thr, 10);
        s_thr(n) = nnz(R_bin)/(nvoxels*nvoxels);
        disp('Computing degree ...')
        %degree: bin
        tmpdc = IPN_centDegree(R_bin);
        disp('Computing subgraph ...')
        %subgraph: bin
        if prod(full(tmpdc)) == 0
            disp('Notice: not a fully connected graph!')
            tmp = IPN_centNSubgraph(R_bin);
            nii = zeros(prod(dims(1:3)),1);
            nii(idx) = full(tmp); nii = reshape(nii, dims(1), dims(2), dims(3));
            save_avw(nii, [outfprefix '/nsc_bin_r' num2str(n) '.nii.gz'], 'f', [4 4 4 1])
            tmp_z = zscore(tmp);
            nii = zeros(prod(dims(1:3)),1);
            nii(idx) = tmp_z; nii = reshape(nii, dims(1), dims(2), dims(3));
            save_avw(nii, [outfprefix '/nsc_bin_r' num2str(n) '_zscore.nii.gz'], 'f', [4 4 4 1])
        else
            %subgraph: bin
            tmp = IPN_centNSubgraph(R_bin);
            nii = zeros(prod(dims(1:3)),1);
            nii(idx) = full(tmp); nii = reshape(nii, dims(1), dims(2), dims(3));
            save_avw(nii, [outfprefix '/nsc_bin_r' num2str(n) '.nii.gz'], 'f', [4 4 4 1])
            tmp_z = zscore(tmp);
            nii = zeros(prod(dims(1:3)),1);
            nii(idx) = tmp_z; nii = reshape(nii, dims(1), dims(2), dims(3));
            save_avw(nii, [outfprefix '/nsc_bin_r' num2str(n) '_zscore.nii.gz'], 'f', [4 4 4 1])
            %subgraph: wei
            tmp = IPN_centNSubgraph(R_wei, 'w');
            nii = zeros(prod(dims(1:3)),1);
            nii(idx) = full(tmp); nii = reshape(nii, dims(1), dims(2), dims(3));
            save_avw(nii, [outfprefix '/nsc_wei_r' num2str(n) '.nii.gz'], 'f', [4 4 4 1])
            tmp_z = zscore(tmp);
            nii = zeros(prod(dims(1:3)),1);
            nii(idx) = tmp_z; nii = reshape(nii, dims(1), dims(2), dims(3));
            save_avw(nii, [outfprefix '/nsc_wei_r' num2str(n) '_zscore.nii.gz'], 'f', [4 4 4 1])
        end
    end
