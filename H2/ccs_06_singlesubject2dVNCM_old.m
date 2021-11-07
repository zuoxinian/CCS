function [err] = ccs_06_singlesubject2dVNCM( ana_dir, sub_list, rest_name, func_dir_name, cent_idx, fs_home, fsaverage, p_thr, grp_mask_lh, grp_mask_rh, savemat)
%CCS_06_SINGLESUBJECT2dVNCM Computing the VEREX-WISE CENTRALITY on the surface.
%   ana_dir -- full path of the analysis directory
%   sub_list -- full path of the list of subjects
%   rest_name -- the name of rest raw data (no extention)
%   func_dir_name -- the name of functional directory
%   cent_idx -- the indices of centrality to be computed [dc sc ec pc]
%   fs_home -- freesurfer home directory
%   fsaverage -- the fsaverage file name
%   p_thr -- the thresholds of p-value 
%   grp_mask_lh -- the full path of lh group mask for network analysis
%   grp_mask_rh -- the full path of rh group mask for network analysis
%   savemat -- if save all matrices
%
%   Note: need to add hemiConnectome function (both intra- and
%   inter-hemispher functionality) to offer the ability of investigate the
%   data for both hemispheres, respectively.

% Author: Xi-Nian Zuo at IPCAS, Dec., 17, 2011.
% Modified: Xi-Nian Zuo at IPCAS, Sept., 22, 2013.

if nargin < 11
    disp('Usage: ccs_06_singlesubject2dVNCM( ana_dir, sub_list, rest_name, func_dir_name, cent_idx, fs_home, fsaverage, p_thr, grp_mask_lh, grp_mask_rh, savemat)')
    exit
end

%% FSAVERAGE: Searching labels in aparc.a2009s.annot
fannot = [fs_home '/subjects/' fsaverage '/label/lh.aparc.a2009s.annot'];
vertices_lh = read_annotation(fannot);
nVertices_lh = numel(vertices_lh);
fannot = [fs_home '/subjects/' fsaverage '/label/rh.aparc.a2009s.annot'];
vertices_rh = read_annotation(fannot);
nVertices_rh = numel(vertices_rh);
clear fannot
%% SUBINFO
fid = fopen(sub_list) ;
tmpcell = textscan(fid, '%s'); 
fclose(fid);
subs = tmpcell{1} ; nsubs = numel(subs);
%% LOAD MASK
maskhdr_lh = load_nifti(grp_mask_lh); idx_lh_mask = (maskhdr_lh.vol > 0);
maskhdr_rh = load_nifti(grp_mask_rh); idx_rh_mask = (maskhdr_rh.vol > 0);
nVertices_mask = nnz(idx_lh_mask) + nnz(idx_rh_mask);
maskhdr_lh.datatype = 16; maskhdr_lh.descrip = ['CCS ' date];
maskhdr_rh.datatype = 16; maskhdr_rh.descrip = ['CCS ' date];
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
    cent_dir = [func_dir '/VNCM']; 
    if ~exist(cent_dir, 'dir')
        mkdir(cent_dir);
    end
    if ~exist([cent_dir '/lh.ec.z.bin.p1.' fsaverage '.nii.gz'], 'file')
        %lh
        fname = [func_dir '/gs-removal/' rest_name '.pp.sm0.' fsaverage '.lh.nii.gz'];
        tmphdr_lh = load_nifti(fname); vol_lh = squeeze(tmphdr_lh.vol); 
        ntp = size(vol_lh,2) ; clear tmphdr_lh
        %rh
        fname = [func_dir '/gs-removal/' rest_name '.pp.sm0.' fsaverage '.rh.nii.gz'];
        tmphdr_rh = load_nifti(fname); vol_rh = squeeze(tmphdr_rh.vol);
        clear tmphdr_rh
        %p_thrs loop
        for n=1:n_thr
            r_thr(n) = IPN_pval2corr(1-p_thr(n), ntp);
            %Compute the R matrix
            vol_bh = [vol_lh(idx_lh_mask,:); vol_rh(idx_rh_mask,:)]';
            [R_bin, R_wei] = IPN_calLCAMw(vol_bh, r_thr(n), 10);
            adjMatrixB{n} = R_bin; adjMatrixW{n} = R_wei;
            s_thr(n) = nnz(R_bin)/(nVertices_mask*(nVertices_mask-1));
            %degree
            if cent_idx(1)
                disp(['Computing degree centrality at p = ' num2str(p_thr(n)) ' ...'])
                %% bin
                tmpdc = IPN_centDegree(R_bin); 
                % raw
                tmp = tmpdc;
                DC_lh = zeros(nVertices_lh,1); DC_rh = zeros(nVertices_rh,1); 
                DC_lh(idx_lh_mask) = tmp(1:nnz(idx_lh_mask));
                DC_rh(idx_rh_mask) = tmp(nnz(idx_lh_mask)+1:end);
                maskhdr_lh.vol = DC_lh; fout = [cent_dir '/lh.dc.bin.p' num2str(n) '.' fsaverage '.nii.gz'];
                err = save_nifti(maskhdr_lh, fout);
                maskhdr_rh.vol = DC_rh; fout = [cent_dir '/rh.dc.bin.p' num2str(n) '.' fsaverage '.nii.gz'];
                err = save_nifti(maskhdr_rh, fout);
                %z-score
                tmp = zscore(tmpdc);
                DC_lh = zeros(nVertices_lh,1); DC_rh = zeros(nVertices_rh,1); 
                DC_lh(idx_lh_mask) = tmp(1:nnz(idx_lh_mask));
                DC_rh(idx_rh_mask) = tmp(nnz(idx_lh_mask)+1:end);
                maskhdr_lh.vol = DC_lh; fout = [cent_dir '/lh.dc.z.bin.p' num2str(n) '.' fsaverage '.nii.gz'];
                err = save_nifti(maskhdr_lh, fout);
                maskhdr_rh.vol = DC_rh; fout = [cent_dir '/rh.dc.z.bin.p' num2str(n) '.' fsaverage '.nii.gz'];
                err = save_nifti(maskhdr_rh, fout);
                %% weighted
                tmpdc = IPN_centDegree(atanh(R_wei)); 
                %raw
                tmp = tmpdc;
                DC_lh = zeros(nVertices_lh,1); DC_rh = zeros(nVertices_rh,1); 
                DC_lh(idx_lh_mask) = tmp(1:nnz(idx_lh_mask));
                DC_rh(idx_rh_mask) = tmp(nnz(idx_lh_mask)+1:end);
                maskhdr_lh.vol = DC_lh; fout = [cent_dir '/lh.dc.wei.p' num2str(n) '.' fsaverage '.nii.gz'];
                err = save_nifti(maskhdr_lh, fout);
                maskhdr_rh.vol = DC_rh; fout = [cent_dir '/rh.dc.wei.p' num2str(n) '.' fsaverage '.nii.gz'];
                err = save_nifti(maskhdr_rh, fout);
                %z-score
                tmp = zscore(tmpdc);
                DC_lh = zeros(nVertices_lh,1); DC_rh = zeros(nVertices_rh,1); 
                DC_lh(idx_lh_mask) = tmp(1:nnz(idx_lh_mask));
                DC_rh(idx_rh_mask) = tmp(nnz(idx_lh_mask)+1:end);
                maskhdr_lh.vol = DC_lh; fout = [cent_dir '/lh.dc.z.wei.p' num2str(n) '.' fsaverage '.nii.gz'];
                err = save_nifti(maskhdr_lh, fout);
                maskhdr_rh.vol = DC_rh; fout = [cent_dir '/rh.dc.z.wei.p' num2str(n) '.' fsaverage '.nii.gz'];
                err = save_nifti(maskhdr_rh, fout);
            end
            if cent_idx(2)
                disp(['Computing subgraph centrality at p = ' num2str(p_thr(n)) ' ...'])
                %% bin
                tmpsc = IPN_centSubgraph(R_bin); 
                %raw
                tmp = tmpsc;
                SC_lh = zeros(nVertices_lh,1); SC_rh = zeros(nVertices_rh,1); 
                SC_lh(idx_lh_mask) = tmp(1:nnz(idx_lh_mask));
                SC_rh(idx_rh_mask) = tmp(nnz(idx_lh_mask)+1:end);
                maskhdr_lh.vol = SC_lh; fout = [cent_dir '/lh.sc.bin.p' num2str(n) '.' fsaverage '.nii.gz'];
                err = save_nifti(maskhdr_lh, fout);
                maskhdr_rh.vol = SC_rh; fout = [cent_dir '/rh.sc.bin.p' num2str(n) '.' fsaverage '.nii.gz'];
                err = save_nifti(maskhdr_rh, fout);
                %z-score
                tmp = zscore(tmpsc);
                SC_lh = zeros(nVertices_lh,1); SC_rh = zeros(nVertices_rh,1); 
                SC_lh(idx_lh_mask) = tmp(1:nnz(idx_lh_mask));
                SC_rh(idx_rh_mask) = tmp(nnz(idx_lh_mask)+1:end);
                maskhdr_lh.vol = SC_lh; fout = [cent_dir '/lh.sc.z.bin.p' num2str(n) '.' fsaverage '.nii.gz'];
                err = save_nifti(maskhdr_lh, fout);
                maskhdr_rh.vol = SC_rh; fout = [cent_dir '/rh.sc.z.bin.p' num2str(n) '.' fsaverage '.nii.gz'];
                err = save_nifti(maskhdr_rh, fout);
                %warn not fully connected graph
                if prod(full(tmpdc)) == 0 ; disp('Notice: not a fully connected graph!'); end
                %% weighted
                %warn not fully connected graph
                if prod(full(tmpdc)) == 0 ; 
                    disp('Notice: not a fully connected graph! Skip weighted subgraph centrality!');
                else
                    tmpsc = IPN_centSubgraph(atanh(R_wei), 1); 
                    %raw
                    tmp = tmpsc;
                    SC_lh = zeros(nVertices_lh,1); SC_rh = zeros(nVertices_rh,1); 
                    SC_lh(idx_lh_mask) = tmp(1:nnz(idx_lh_mask));
                    SC_rh(idx_rh_mask) = tmp(nnz(idx_lh_mask)+1:end);
                    maskhdr_lh.vol = SC_lh; fout = [cent_dir '/lh.sc.wei.p' num2str(n) '.' fsaverage '.nii.gz'];
                	err = save_nifti(maskhdr_lh, fout);
                    maskhdr_rh.vol = SC_rh; fout = [cent_dir '/rh.sc.wei.p' num2str(n) '.' fsaverage '.nii.gz'];
                    err = save_nifti(maskhdr_rh, fout);
                    %z-score
                    tmp = zscore(tmpsc);
                    SC_lh = zeros(nVertices_lh,1); SC_rh = zeros(nVertices_rh,1); 
                    SC_lh(idx_lh_mask) = tmp(1:nnz(idx_lh_mask));
                    SC_rh(idx_rh_mask) = tmp(nnz(idx_lh_mask)+1:end);
                    maskhdr_lh.vol = SC_lh; fout = [cent_dir '/lh.sc.z.wei.p' num2str(n) '.' fsaverage '.nii.gz'];
                    err = save_nifti(maskhdr_lh, fout);
                    maskhdr_rh.vol = SC_rh; fout = [cent_dir '/rh.sc.z.wei.p' num2str(n) '.' fsaverage '.nii.gz'];
                    err = save_nifti(maskhdr_rh, fout);
                end
            end
            %eigenvector
            if cent_idx(3)
                disp(['Computing eigenvector centrality at p = ' num2str(p_thr(n)) ' ...'])
                %% bin
                tmpec = IPN_centEigenvector(R_bin); 
                %raw
                tmp = tmpec;
                EC_lh = zeros(nVertices_lh,1); EC_rh = zeros(nVertices_rh,1); 
                EC_lh(idx_lh_mask) = tmp(1:nnz(idx_lh_mask));
                EC_rh(idx_rh_mask) = tmp(nnz(idx_lh_mask)+1:end);
                maskhdr_lh.vol = EC_lh; fout = [cent_dir '/lh.ec.bin.p' num2str(n) '.' fsaverage '.nii.gz'];
                err = save_nifti(maskhdr_lh, fout);
                maskhdr_rh.vol = EC_rh; fout = [cent_dir '/rh.ec.bin.p' num2str(n) '.' fsaverage '.nii.gz'];
                err = save_nifti(maskhdr_rh, fout);
                %z-score
                tmp = zscore(tmpec);
                EC_lh = zeros(nVertices_lh,1); EC_rh = zeros(nVertices_rh,1); 
                EC_lh(idx_lh_mask) = tmp(1:nnz(idx_lh_mask));
                EC_rh(idx_rh_mask) = tmp(nnz(idx_lh_mask)+1:end);
                maskhdr_lh.vol = EC_lh; fout = [cent_dir '/lh.ec.z.bin.p' num2str(n) '.' fsaverage '.nii.gz'];
                err = save_nifti(maskhdr_lh, fout);
                maskhdr_rh.vol = EC_rh; fout = [cent_dir '/rh.ec.z.bin.p' num2str(n) '.' fsaverage '.nii.gz'];
                err = save_nifti(maskhdr_rh, fout);
            %% weighted: needs improvements.
%             tmpec = IPN_centEigenvector(atanh(R_wei)); 
%             %raw
%             tmp = tmpec;
%             EC_lh = zeros(nVertices_lh,1); EC_rh = zeros(nVertices_rh,1); 
%             EC_lh(idx_lh_mask) = tmp(1:nnz(idx_lh_mask));
%             EC_rh(idx_rh_mask) = tmp(nnz(idx_lh_mask)+1:end);
%             maskhdr_lh.vol = EC_lh; fout = [cent_dir '/lh.ec.wei.p' num2str(n) '.' fsaverage '.nii.gz'];
%             err = save_nifti(maskhdr_lh, fout);
%             maskhdr_rh.vol = EC_rh; fout = [cent_dir '/rh.ec.wei.p' num2str(n) '.' fsaverage '.nii.gz'];
%             err = save_nifti(maskhdr_rh, fout);
%             %z-score
%             tmp = zscore(tmpec);
%             EC_lh = zeros(nVertices_lh,1); EC_rh = zeros(nVertices_rh,1); 
%             EC_lh(idx_lh_mask) = tmp(1:nnz(idx_lh_mask));
%             EC_rh(idx_rh_mask) = tmp(nnz(idx_lh_mask)+1:end);
%             maskhdr_lh.vol = EC_lh; fout = [cent_dir '/lh.ec.z.wei.p' num2str(n) '.' fsaverage '.nii.gz'];
%             err = save_nifti(maskhdr_lh, fout);
%             maskhdr_rh.vol = EC_rh; fout = [cent_dir '/rh.ec.z.wei.p' num2str(n) '.' fsaverage '.nii.gz'];
%             err = save_nifti(maskhdr_rh, fout);
            end
            %page rank
            if cent_idx(4)
                disp(['Computing pagerank centrality at p = ' num2str(p_thr(n)) ' ...'])
                %% bin
                tmppc = IPN_centPagerank(R_bin); 
                %raw
                tmp = tmppc;
                PC_lh = zeros(nVertices_lh,1); PC_rh = zeros(nVertices_rh,1); 
                PC_lh(idx_lh_mask) = tmp(1:nnz(idx_lh_mask));
                PC_rh(idx_rh_mask) = tmp(nnz(idx_lh_mask)+1:end);
                maskhdr_lh.vol = PC_lh; fout = [cent_dir '/lh.pc.bin.p' num2str(n) '.' fsaverage '.nii.gz'];
                err = save_nifti(maskhdr_lh, fout);
                maskhdr_rh.vol = PC_rh; fout = [cent_dir '/rh.pc.bin.p' num2str(n) '.' fsaverage '.nii.gz'];
                err = save_nifti(maskhdr_rh, fout);
                %z-score
                tmp = zscore(tmppc);
                PC_lh = zeros(nVertices_lh,1); PC_rh = zeros(nVertices_rh,1); 
                PC_lh(idx_lh_mask) = tmp(1:nnz(idx_lh_mask));
                PC_rh(idx_rh_mask) = tmp(nnz(idx_lh_mask)+1:end);
                maskhdr_lh.vol = PC_lh; fout = [cent_dir '/lh.pc.z.bin.p' num2str(n) '.' fsaverage '.nii.gz'];
                err = save_nifti(maskhdr_lh, fout);
                maskhdr_rh.vol = PC_rh; fout = [cent_dir '/rh.pc.z.bin.p' num2str(n) '.' fsaverage '.nii.gz'];
                err = save_nifti(maskhdr_rh, fout);
                %% weighted
                tmppc = IPN_centPagerank(atanh(R_wei)); 
                %raw
                tmp = tmppc;
                PC_lh = zeros(nVertices_lh,1); PC_rh = zeros(nVertices_rh,1); 
                PC_lh(idx_lh_mask) = tmp(1:nnz(idx_lh_mask));
                PC_rh(idx_rh_mask) = tmp(nnz(idx_lh_mask)+1:end);
                maskhdr_lh.vol = PC_lh; fout = [cent_dir '/lh.pc.wei.p' num2str(n) '.' fsaverage '.nii.gz'];
                err = save_nifti(maskhdr_lh, fout);
                maskhdr_rh.vol = PC_rh; fout = [cent_dir '/rh.pc.wei.p' num2str(n) '.' fsaverage '.nii.gz'];
                err = save_nifti(maskhdr_rh, fout);
                %z-score
                tmp = zscore(tmppc);
                PC_lh = zeros(nVertices_lh,1); PC_rh = zeros(nVertices_rh,1); 
                PC_lh(idx_lh_mask) = tmp(1:nnz(idx_lh_mask));
                PC_rh(idx_rh_mask) = tmp(nnz(idx_lh_mask)+1:end);
                maskhdr_lh.vol = PC_lh; fout = [cent_dir '/lh.pc.z.wei.p' num2str(n) '.' fsaverage '.nii.gz'];
                err = save_nifti(maskhdr_lh, fout);
                maskhdr_rh.vol = PC_rh; fout = [cent_dir '/rh.pc.z.wei.p' num2str(n) '.' fsaverage '.nii.gz'];
                err = save_nifti(maskhdr_rh, fout);
            end
        end
    else
        err = 0;
    end
    if strcmp(savemat, 'true')
        save([cent_dir '/threshs_surf.mat'], 'p_thr', 'r_thr', 's_thr', 'adjMatrixB', 'adjMatrixW', '-v7.3')
    else
        save([cent_dir '/threshs_surf.mat'], 'p_thr', 'r_thr', 's_thr')
    end
end

