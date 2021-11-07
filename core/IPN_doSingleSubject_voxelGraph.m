function [ R_bin, R_wei, nvoxels, s_thr, r_thr, p, n_tp ] = IPN_doSingleSubject_voxelGraph( infname, maskfname, gmfname, p, gm_thr )
% Summary of this function goes here
%   Detailed explanation goes here
% Xinian.Zuo@nyumc.org

    if nargin < 4
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
    end
