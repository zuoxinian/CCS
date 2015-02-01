function [ R_bin, s_thr, r_thr, p ] = ccs_06_singlesubjectVNCM( ana_dir, sub_list, rest_name, func_dir_name, cent_idx, maskfname, p_thr, gmfname, gm_thr )
%CCS_06_SINGLESUBJECTCENTV_SURF Computing the VOXEL-WISE CENTRALITY on the surface.
%   ana_dir -- full path of the analysis directory
%   sub_list -- full path of the list of subjects
%   rest_name -- the name of rest raw data (no extention)
%   func_dir_name -- the name of functional directory
%   cent_idx -- the indices of centrality to be computed [dc sc ec pc]
%   maskfname -- full path of the group mask
%   p_thr -- thresholds of p-value
%   gmfname -- the full path of the gray matter template 
%   gm_tht -- the threshold of gray matter
%
% Author: Xi-Nian Zuo at IPCAS, Dec., 17, 2011.
if nargin < 9
    disp('Usage: ccs_06_singlesubjectCENTv( ana_dir, sub_list, rest_name, func_dir_name, cent_idx, maskfname, p_thr, gmfname, gm_thr)')
    exit
end
%% SUBINFO
subs = importdata(sub_list); nsubs = numel(subs);
if ~iscell(subs)
    subs = num2cell(subs);
end
%% LOAD MASK
%[nii, dim, scales] = read_avw(maskfname); %FSL version
maskHDR = load_nifti(maskfname); %FS version
nii = maskHDR.vol; dim = maskHDR.dim(2:4); %FS version
mask = reshape(nii, prod(dim), 1);
clear nii
%nii = read_avw(gmfname); %FSL version
gmHDR = load_nifti(gmfname); %FS version
nii = gmHDR.vol; %FS version
gm = reshape(nii, prod(dim), 1);
idx = find(gm.*mask > gm_thr);
nvoxels = length(idx);
%% LOOP SUBJECTS
n_thr = length(p_thr); r_thr = zeros(n_thr,1); s_thr = zeros(n_thr,1);
for k=1:nsubs
    if isnumeric(subs{k})
        disp(['Loading RfMRI data for subject ' num2str(subs{k}) ' ...'])
        func_dir = [ana_dir '/' num2str(subs{k}) '/' func_dir_name];
    else
        disp(['Loading RfMRI data for subject ' subs{k} ' ...'])
        func_dir = [ana_dir '/' subs{k} '/' func_dir_name];
    end
    cent_dir = [func_dir '/VNCM']; mkdir(cent_dir);
    infname = [cent_dir '/' rest_name '.sm0.mni152.4mm.nii.gz'];
    %[nii, dims] = read_avw(infname);
    rfmriHDR = load_nifti(infname); %FS version
    nii = rfmriHDR.vol; dims = rfmriHDR.dim(2:5); %FS version
    n_tp = dims(4);
    lfo_res = reshape(nii, prod(dims(1:3)), n_tp);
    clear nii
    lfo_res_gm = lfo_res(idx, :);
    clear lfo_res nii
    
    for n=1:length(r_thr)
        r_thr(n) = IPN_pval2corr(1-p_thr(n), n_tp);
        % Compute correlation matrix
        [R_bin, R_wei] = IPN_calLCAM(lfo_res_gm', r_thr, 10);
        s_thr(n) = nnz(R_bin)/(nvoxels*(nvoxels-1));
      if cent_idx(1)
        disp(['Computing degree centrality at p = ' num2str(p_thr(n)) ' ...'])
        %degree: bin
        tmpdc = IPN_centDegree(R_bin);
        tmp = tmpdc;
        nii = zeros(prod(dims(1:3)),1);
        nii(idx) = full(tmp); nii = reshape(nii, dims(1), dims(2), dims(3));
        fout = [cent_dir '/dc.bin.p' num2str(n) '.mni152.nii.gz'];
        %save_avw(nii, fout, 'f', [scales(1:3); 1]) % FSL version
        maskHDR.datatype = 16; maskHDR.descrip = ['CCS ' date];
        maskHDR.vol = nii ; err = save_nifti(maskHDR, fout);
        tmp_z = zscore(tmp);
        nii = zeros(prod(dims(1:3)),1);
        nii(idx) = tmp_z; nii = reshape(nii, dims(1), dims(2), dims(3));
        fout = [cent_dir '/dc.bin.z.p' num2str(n) '.mni152.nii.gz'];
        %save_avw(nii, fout, 'f', [scales(1:3); 1]) %FSL version
        maskHDR.datatype = 16; maskHDR.descrip = ['CCS ' date];
        maskHDR.vol = nii ; err = save_nifti(maskHDR, fout);
        %degree: wei
        tmp = IPN_centDegree(R_wei);
        nii = zeros(prod(dims(1:3)),1);
        nii(idx) = full(tmp); nii = reshape(nii, dims(1), dims(2), dims(3));
        fout = [cent_dir '/dc.wei.p' num2str(n) '.mni152.nii.gz'];
        %save_avw(nii, fout, 'f', [scales(1:3); 1]) %FSL version
        maskHDR.datatype = 16; maskHDR.descrip = ['CCS ' date];
        maskHDR.vol = nii ; err = save_nifti(maskHDR, fout);
        tmp_z = zscore(tmp);
        nii = zeros(prod(dims(1:3)),1);
        nii(idx) = tmp_z; nii = reshape(nii, dims(1), dims(2), dims(3));
        fout = [cent_dir '/dc.wei.z.p' num2str(n) '.mni152.nii.gz'];
        %save_avw(nii, fout, 'f', [scales(1:3); 1]) %FSL version
        maskHDR.datatype = 16; maskHDR.descrip = ['CCS ' date];
        maskHDR.vol = nii ; err = save_nifti(maskHDR, fout);
      end
      if cent_idx(3)
        disp(['Computing eigenvector centrality at p = ' num2str(p_thr(n)) ' ...'])
        %eigenvector: bin
        tmp = IPN_centEigenvector(R_bin);
        nii = zeros(prod(dims(1:3)),1);
        nii(idx) = full(tmp); nii = reshape(nii, dims(1), dims(2), dims(3));
        fout = [cent_dir '/ec.bin.p' num2str(n) '.mni152.nii.gz'];
        %save_avw(nii, fout, 'f', [scales(1:3); 1]) %FSL version
        maskHDR.datatype = 16; maskHDR.descrip = ['CCS ' date];
        maskHDR.vol = nii ; err = save_nifti(maskHDR, fout);
        tmp_z = zscore(tmp);
        nii = zeros(prod(dims(1:3)),1);
        nii(idx) = tmp_z; nii = reshape(nii, dims(1), dims(2), dims(3));
        fout = [cent_dir '/ec.bin.z.p' num2str(n) '.mni152.nii.gz'];
        %save_avw(nii, fout, 'f', [scales(1:3); 1]) %FSL version
        maskHDR.datatype = 16; maskHDR.descrip = ['CCS ' date];
        maskHDR.vol = nii ; err = save_nifti(maskHDR, fout);
        %eigenvector: wei
        tmp = IPN_centEigenvector(R_wei);
        nii = zeros(prod(dims(1:3)),1);
        nii(idx) = full(tmp); nii = reshape(nii, dims(1), dims(2), dims(3));
        fout = [cent_dir '/ec.wei.p' num2str(n) '.mni152.nii.gz'];
        %save_avw(nii, fout, 'f', [scales(1:3); 1]) %FSL version
        maskHDR.datatype = 16; maskHDR.descrip = ['CCS ' date];
        maskHDR.vol = nii ; err = save_nifti(maskHDR, fout);
        tmp_z = zscore(tmp);
        nii = zeros(prod(dims(1:3)),1);
        nii(idx) = tmp_z; nii = reshape(nii, dims(1), dims(2), dims(3));
        fout = [cent_dir '/ec.wei.z.p' num2str(n) '.mni152.nii.gz'];
        %save_avw(nii, fout, 'f', [scales(1:3); 1]) %FSL version
        maskHDR.datatype = 16; maskHDR.descrip = ['CCS ' date];
        maskHDR.vol = nii ; err = save_nifti(maskHDR, fout);
      end
      if cent_idx(2)
        disp(['Computing subgraph centrality at p = ' num2str(p_thr(n)) ' ...'])
        %subgraph: bin
        if prod(full(tmpdc)) == 0
            disp('Notice: not a fully connected graph!')
            tmp = IPN_centSubgraph(R_bin);
            nii = zeros(prod(dims(1:3)),1);
            nii(idx) = full(tmp); nii = reshape(nii, dims(1), dims(2), dims(3));
            fout = [cent_dir '/sc.bin.p' num2str(n) '.mni152.nii.gz'];
            %save_avw(nii, fout, 'f', [scales(1:3); 1]) %FSL version
            maskHDR.datatype = 16; maskHDR.descrip = ['CCS ' date];
            maskHDR.vol = nii ; err = save_nifti(maskHDR, fout);
            tmp_z = zscore(tmp);
            nii = zeros(prod(dims(1:3)),1);
            nii(idx) = tmp_z; nii = reshape(nii, dims(1), dims(2), dims(3));
            fout = [cent_dir '/sc.bin.z.p' num2str(n) '.mni152.nii.gz'];
            %save_avw(nii, fout, 'f', [scales(1:3); 1]) %FSL version
            maskHDR.datatype = 16; maskHDR.descrip = ['CCS ' date];
            maskHDR.vol = nii ; err = save_nifti(maskHDR, fout);
        else
            %subgraph: bin
            tmp = IPN_centSubgraph(R_bin);
            nii = zeros(prod(dims(1:3)),1);
            nii(idx) = full(tmp); nii = reshape(nii, dims(1), dims(2), dims(3));
            fout = [cent_dir '/sc.bin.p' num2str(n) '.mni152.nii.gz'];
            %save_avw(nii, fout, 'f', [scales(1:3); 1]) %FSL version
            maskHDR.datatype = 16; maskHDR.descrip = ['CCS ' date];
            maskHDR.vol = nii ; err = save_nifti(maskHDR, fout);
            tmp_z = zscore(tmp);
            nii = zeros(prod(dims(1:3)),1);
            nii(idx) = tmp_z; nii = reshape(nii, dims(1), dims(2), dims(3));
            fout = [cent_dir '/sc.bin.z.p' num2str(n) '.mni152.nii.gz'];
            %save_avw(nii, fout, 'f', [scales(1:3); 1]) %FSL version
            maskHDR.datatype = 16; maskHDR.descrip = ['CCS ' date];
            maskHDR.vol = nii ; err = save_nifti(maskHDR, fout);
            %subgraph: wei
            tmp = IPN_centSubgraph(R_wei, 'w');
            nii = zeros(prod(dims(1:3)),1);
            nii(idx) = full(tmp); nii = reshape(nii, dims(1), dims(2), dims(3));
            fout = [cent_dir '/sc.wei.p' num2str(n) '.mni152.nii.gz'];
            %save_avw(nii, fout, 'f', [scales(1:3); 1]) %FSL version
            maskHDR.datatype = 16; maskHDR.descrip = ['CCS ' date];
            maskHDR.vol = nii ; err = save_nifti(maskHDR, fout);
            tmp_z = zscore(tmp);
            nii = zeros(prod(dims(1:3)),1);
            nii(idx) = tmp_z; nii = reshape(nii, dims(1), dims(2), dims(3));
            fout = [cent_dir '/sc.wei.z.p' num2str(n) '.mni152.nii.gz'];
            %save_avw(nii, fout, 'f', [scales(1:3); 1]) %FSL version
            maskHDR.datatype = 16; maskHDR.descrip = ['CCS ' date];
            maskHDR.vol = nii ; err = save_nifti(maskHDR, fout);
        end
      end
      if cent_idx(4)
        disp(['Computing pagerank centrality at p = ' num2str(p_thr(n)) ' ...'])
        %pagerank: bin
        tmp = IPN_centPagerank(R_bin);
        nii = zeros(prod(dims(1:3)),1);
        nii(idx) = full(tmp); nii = reshape(nii, dims(1), dims(2), dims(3));
        fout = [cent_dir '/pc.bin.p' num2str(n) '.mni152.nii.gz'];
        %save_avw(nii, fout, 'f', [scales(1:3); 1]) %FSL version
        maskHDR.datatype = 16; maskHDR.descrip = ['CCS ' date];
        maskHDR.vol = nii ; err = save_nifti(maskHDR, fout);
        tmp_z = zscore(tmp);
        nii = zeros(prod(dims(1:3)),1);
        nii(idx) = tmp_z; nii = reshape(nii, dims(1), dims(2), dims(3));
        fout = [cent_dir '/pc.bin.z.p' num2str(n) '.mni152.nii.gz'];
        %save_avw(nii, fout, 'f', [scales(1:3); 1]) %FSL version
        maskHDR.datatype = 16; maskHDR.descrip = ['CCS ' date];
        maskHDR.vol = nii ; err = save_nifti(maskHDR, fout);
        %pagerank: wei
        tmp = IPN_centPagerank(R_wei);
        nii = zeros(prod(dims(1:3)),1);
        nii(idx) = full(tmp); nii = reshape(nii, dims(1), dims(2), dims(3));
        fout = [cent_dir '/pc.wei.p' num2str(n) '.mni152.nii.gz'];
        %save_avw(nii, fout, 'f', [scales(1:3); 1]) %FSL version
        maskHDR.datatype = 16; maskHDR.descrip = ['CCS ' date];
        maskHDR.vol = nii ; err = save_nifti(maskHDR, fout);
        tmp_z = zscore(tmp);
        nii = zeros(prod(dims(1:3)),1);
        nii(idx) = tmp_z; nii = reshape(nii, dims(1), dims(2), dims(3));
        fout = [cent_dir '/pc.wei.z.p' num2str(n) '.mni152.nii.gz'];
        %save_avw(nii, fout, 'f', [scales(1:3); 1]) %FSL version
        maskHDR.datatype = 16; maskHDR.descrip = ['CCS ' date];
        maskHDR.vol = nii ; err = save_nifti(maskHDR, fout);
      end
    end
    save([cent_dir '/threshs.dat'], 'p_thr', 'r_thr', 's_thr', 'gm_thr', '-ASCII')
end
