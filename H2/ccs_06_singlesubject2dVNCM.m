function [err] = ccs_06_singlesubject2dVNCM( ana_dir, sub_list, ...
    rest_name, func_dir_name, cent_idx, fs_home, fsaverage, ...
    grp_mask_lh, grp_mask_rh, edge_density, savemat)
%CCS_06_SINGLESUBJECT2dVNCM Computing the VEREX-WISE CENTRALITY on the surface.
%   ana_dir -- full path of the analysis directory
%   sub_list -- full path of the list of subjects
%   rest_name -- the name of rest raw data (no extention)
%   func_dir_name -- the name of functional directory
%   cent_idx -- the indices of centrality to be computed [dc sc ec pc]
%   fs_home -- freesurfer home directory
%   fsaverage -- the fsaverage file name
%   grp_mask_lh -- the full path of lh group mask for network analysis
%   grp_mask_rh -- the full path of rh group mask for network analysis
%   edge_density -- the thresholds of edge density 
%   savemat -- if save all matrices

% Author: Xi-Nian Zuo at IPCAS, Dec., 17, 2011.
% Modified: Xi-Nian Zuo at IPCAS, Sept., 22, 2013.
% Modified: Xi-Nian Zuo at IPCAS, Oct., 17, 2014.

if nargin < 11
    disp(['Usage: ccs_06_singlesubject2dVNCM( ana_dir, sub_list, ' ...
        'rest_name, func_dir_name, cent_idx, fs_home, fsaverage, ' ...
        'grp_mask_lh, grp_mask_rh, edge_density, savemat)'])
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
centers = -1:0.001:1; n_thr = length(edge_density); 
node_alone = zeros(n_thr, 1); r_thr = zeros(n_thr,1);
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
    if ~exist([cent_dir '/lh.ec.bin.graph1.' fsaverage '.nii.gz'], 'file')
        %lh
        fname = [func_dir '/' rest_name '.pp.sm0.' fsaverage '.lh.nii.gz'];
        tmphdr_lh = load_nifti(fname); vol_lh = squeeze(tmphdr_lh.vol); 
        tsmat_lh = vol_lh(idx_lh_mask,:)'; clear tmphdr_lh
        %rh
        fname = [func_dir '/' rest_name '.pp.sm0.' fsaverage '.rh.nii.gz'];
        tmphdr_rh = load_nifti(fname); vol_rh = squeeze(tmphdr_rh.vol);
        tsmat_rh = vol_rh(idx_rh_mask,:)'; clear tmphdr_rh
        %LL correlation matrix
        corrLL = IPN_fastCorr(tsmat_lh, tsmat_lh);
        tmpTRI = tril(corrLL, -1); tmpNNZ = tmpTRI(tmpTRI~=0);
        number_edges_LL = hist(tmpNNZ(:), centers);
        %LR correlation matrix
        corrLR = IPN_fastCorr(tsmat_lh, tsmat_rh);
        %RL correlation matrix
        corrRL = IPN_fastCorr(tsmat_rh, tsmat_lh);
        number_edges_RL = hist(corrRL(:), centers);
        %RR correlation matrix
        corrRR = IPN_fastCorr(tsmat_rh, tsmat_rh);
        tmpTRI = tril(corrRR, -1); tmpNNZ = tmpTRI(tmpTRI~=0);
        number_edges_RR = hist(tmpNNZ(:), centers);
        %Merge BH
        number_edges = number_edges_LL + number_edges_RL + number_edges_RR;
        cdf_edges = cumsum(number_edges)/sum(number_edges);
        %edge_density loop
        for n=1:n_thr
            idx_corr_thr = find(cdf_edges >= (1-edge_density(n)));
            corr_thr = centers(idx_corr_thr(1)); r_thr(n) = corr_thr;
            %build up the adjacency matrix
            corrLL(corrLL < corr_thr) = 0; corrLL = sparse(double(corrLL));
            corrLR(corrLR < corr_thr) = 0; corrLR = sparse(double(corrLR));
            corrRL(corrRL < corr_thr) = 0; corrRL = sparse(double(corrRL));
            corrRR(corrRR < corr_thr) = 0; corrRR = sparse(double(corrRR));
            corr = [corrLL corrLR; corrRL corrRR]; 
            corr = corr - corr.*speye(nVertices_mask);
            R_wei = atanh(corr); [row, col, v] = find(R_wei); 
            R_bin = sparse(row,col,v./v,nVertices_mask, nVertices_mask); 
            adjMatrixB{n} = R_bin; adjMatrixW{n} = R_wei;
            %degree
            if cent_idx(1)
                disp(['Computing DC at correlation = ' num2str(corr_thr) ' ...'])
                % bin
                tmpdc = IPN_centDegree(R_bin);
                if nnz(tmpdc)<(length(tmpdc)-1)
                    node_alone(n) = 1;
                end
                % raw
                tmp = tmpdc;
                DC_lh = zeros(nVertices_lh,1); DC_rh = zeros(nVertices_rh,1); 
                DC_lh(idx_lh_mask) = tmp(1:nnz(idx_lh_mask));
                DC_rh(idx_rh_mask) = tmp(nnz(idx_lh_mask)+1:end);
                maskhdr_lh.vol = DC_lh; fout = [cent_dir '/lh.dc.bin.graph' num2str(n) '.' fsaverage '.nii.gz'];
                err = save_nifti(maskhdr_lh, fout);
                maskhdr_rh.vol = DC_rh; fout = [cent_dir '/rh.dc.bin.graph' num2str(n) '.' fsaverage '.nii.gz'];
                err = save_nifti(maskhdr_rh, fout);
                %z-score
%                 tmp = zscore(tmpdc);
%                 DC_lh = zeros(nVertices_lh,1); DC_rh = zeros(nVertices_rh,1); 
%                 DC_lh(idx_lh_mask) = tmp(1:nnz(idx_lh_mask));
%                 DC_rh(idx_rh_mask) = tmp(nnz(idx_lh_mask)+1:end);
%                 maskhdr_lh.vol = DC_lh; fout = [cent_dir '/lh.dc.z.bin.graph' num2str(n) '.' fsaverage '.nii.gz'];
%                 err = save_nifti(maskhdr_lh, fout);
%                 maskhdr_rh.vol = DC_rh; fout = [cent_dir '/rh.dc.z.bin.graph' num2str(n) '.' fsaverage '.nii.gz'];
%                 err = save_nifti(maskhdr_rh, fout);
                %% weighted
                tmpdc = IPN_centDegree(R_wei); 
                %raw
                tmp = tmpdc;
                DC_lh = zeros(nVertices_lh,1); DC_rh = zeros(nVertices_rh,1); 
                DC_lh(idx_lh_mask) = tmp(1:nnz(idx_lh_mask));
                DC_rh(idx_rh_mask) = tmp(nnz(idx_lh_mask)+1:end);
                maskhdr_lh.vol = DC_lh; fout = [cent_dir '/lh.dc.wei.graph' num2str(n) '.' fsaverage '.nii.gz'];
                err = save_nifti(maskhdr_lh, fout);
                maskhdr_rh.vol = DC_rh; fout = [cent_dir '/rh.dc.wei.graph' num2str(n) '.' fsaverage '.nii.gz'];
                err = save_nifti(maskhdr_rh, fout);
                %z-score
%                 tmp = zscore(tmpdc);
%                 DC_lh = zeros(nVertices_lh,1); DC_rh = zeros(nVertices_rh,1); 
%                 DC_lh(idx_lh_mask) = tmp(1:nnz(idx_lh_mask));
%                 DC_rh(idx_rh_mask) = tmp(nnz(idx_lh_mask)+1:end);
%                 maskhdr_lh.vol = DC_lh; fout = [cent_dir '/lh.dc.z.wei.graph' num2str(n) '.' fsaverage '.nii.gz'];
%                 err = save_nifti(maskhdr_lh, fout);
%                 maskhdr_rh.vol = DC_rh; fout = [cent_dir '/rh.dc.z.wei.graph' num2str(n) '.' fsaverage '.nii.gz'];
%                 err = save_nifti(maskhdr_rh, fout);
            end
            if cent_idx(2)
                disp(['Computing SC at correlation = ' num2str(r_thr(n)) ' ...'])
                %% bin
                tmpsc = IPN_centSubgraph(R_bin); 
                %raw
                tmp = tmpsc;
                SC_lh = zeros(nVertices_lh,1); SC_rh = zeros(nVertices_rh,1); 
                SC_lh(idx_lh_mask) = tmp(1:nnz(idx_lh_mask));
                SC_rh(idx_rh_mask) = tmp(nnz(idx_lh_mask)+1:end);
                maskhdr_lh.vol = SC_lh; fout = [cent_dir '/lh.sc.bin.graph' num2str(n) '.' fsaverage '.nii.gz'];
                err = save_nifti(maskhdr_lh, fout);
                maskhdr_rh.vol = SC_rh; fout = [cent_dir '/rh.sc.bin.graph' num2str(n) '.' fsaverage '.nii.gz'];
                err = save_nifti(maskhdr_rh, fout);
                %z-score
%                 tmp = zscore(tmpsc);
%                 SC_lh = zeros(nVertices_lh,1); SC_rh = zeros(nVertices_rh,1); 
%                 SC_lh(idx_lh_mask) = tmp(1:nnz(idx_lh_mask));
%                 SC_rh(idx_rh_mask) = tmp(nnz(idx_lh_mask)+1:end);
%                 maskhdr_lh.vol = SC_lh; fout = [cent_dir '/lh.sc.z.bin.graph' num2str(n) '.' fsaverage '.nii.gz'];
%                 err = save_nifti(maskhdr_lh, fout);
%                 maskhdr_rh.vol = SC_rh; fout = [cent_dir '/rh.sc.z.bin.graph' num2str(n) '.' fsaverage '.nii.gz'];
%                 err = save_nifti(maskhdr_rh, fout);
                %% weighted
                %warn not fully connected graph
                if node_alone(n) 
                    disp('Notice: not a fully connected graph! Skip weighted subgraph centrality!');
                else
                    tmpsc = IPN_centSubgraph(R_wei, 1); 
                    %raw
                    tmp = tmpsc;
                    SC_lh = zeros(nVertices_lh,1); SC_rh = zeros(nVertices_rh,1); 
                    SC_lh(idx_lh_mask) = tmp(1:nnz(idx_lh_mask));
                    SC_rh(idx_rh_mask) = tmp(nnz(idx_lh_mask)+1:end);
                    maskhdr_lh.vol = SC_lh; fout = [cent_dir '/lh.sc.wei.graph' num2str(n) '.' fsaverage '.nii.gz'];
                	err = save_nifti(maskhdr_lh, fout);
                    maskhdr_rh.vol = SC_rh; fout = [cent_dir '/rh.sc.wei.graph' num2str(n) '.' fsaverage '.nii.gz'];
                    err = save_nifti(maskhdr_rh, fout);
                    %z-score
%                     tmp = zscore(tmpsc);
%                     SC_lh = zeros(nVertices_lh,1); SC_rh = zeros(nVertices_rh,1); 
%                     SC_lh(idx_lh_mask) = tmp(1:nnz(idx_lh_mask));
%                     SC_rh(idx_rh_mask) = tmp(nnz(idx_lh_mask)+1:end);
%                     maskhdr_lh.vol = SC_lh; fout = [cent_dir '/lh.sc.z.wei.graph' num2str(n) '.' fsaverage '.nii.gz'];
%                     err = save_nifti(maskhdr_lh, fout);
%                     maskhdr_rh.vol = SC_rh; fout = [cent_dir '/rh.sc.z.wei.graph' num2str(n) '.' fsaverage '.nii.gz'];
%                     err = save_nifti(maskhdr_rh, fout);
                end
            end
            %eigenvector
            if cent_idx(3)
                disp(['Computing EC at correlation = ' num2str(r_thr(n)) ' ...'])
                %% bin
                if node_alone(n) 
                    disp('Notice: not a fully connected graph! Skip weighted subgraph centrality!');
                else
                    tmpec = IPN_centEigenvector(R_bin); 
                    %raw
                    tmp = tmpec;
                    EC_lh = zeros(nVertices_lh,1); EC_rh = zeros(nVertices_rh,1); 
                    EC_lh(idx_lh_mask) = tmp(1:nnz(idx_lh_mask));
                    EC_rh(idx_rh_mask) = tmp(nnz(idx_lh_mask)+1:end);
                    maskhdr_lh.vol = EC_lh; fout = [cent_dir '/lh.ec.bin.graph' num2str(n) '.' fsaverage '.nii.gz'];
                    err = save_nifti(maskhdr_lh, fout);
                    maskhdr_rh.vol = EC_rh; fout = [cent_dir '/rh.ec.bin.graph' num2str(n) '.' fsaverage '.nii.gz'];
                    err = save_nifti(maskhdr_rh, fout);
                %z-score
%                 tmp = zscore(tmpec);
%                 EC_lh = zeros(nVertices_lh,1); EC_rh = zeros(nVertices_rh,1); 
%                 EC_lh(idx_lh_mask) = tmp(1:nnz(idx_lh_mask));
%                 EC_rh(idx_rh_mask) = tmp(nnz(idx_lh_mask)+1:end);
%                 maskhdr_lh.vol = EC_lh; fout = [cent_dir '/lh.ec.z.bin.graph' num2str(n) '.' fsaverage '.nii.gz'];
%                 err = save_nifti(maskhdr_lh, fout);
%                 maskhdr_rh.vol = EC_rh; fout = [cent_dir '/rh.ec.z.bin.graph' num2str(n) '.' fsaverage '.nii.gz'];
%                 err = save_nifti(maskhdr_rh, fout);
                % weighted: needs improvements.
                    tmpec = IPN_centEigenvector(R_wei); 
                    %raw
                    tmp = tmpec;
                    EC_lh = zeros(nVertices_lh,1); EC_rh = zeros(nVertices_rh,1); 
                    EC_lh(idx_lh_mask) = tmp(1:nnz(idx_lh_mask));
                    EC_rh(idx_rh_mask) = tmp(nnz(idx_lh_mask)+1:end);
                    maskhdr_lh.vol = EC_lh; fout = [cent_dir '/lh.ec.wei.graph' num2str(n) '.' fsaverage '.nii.gz'];
                    err = save_nifti(maskhdr_lh, fout);
                    maskhdr_rh.vol = EC_rh; fout = [cent_dir '/rh.ec.wei.graph' num2str(n) '.' fsaverage '.nii.gz'];
                    err = save_nifti(maskhdr_rh, fout);
                %z-score
%                 tmp = zscore(tmpec);
%                 EC_lh = zeros(nVertices_lh,1); EC_rh = zeros(nVertices_rh,1); 
%                 EC_lh(idx_lh_mask) = tmp(1:nnz(idx_lh_mask));
%                 EC_rh(idx_rh_mask) = tmp(nnz(idx_lh_mask)+1:end);
%                 maskhdr_lh.vol = EC_lh; fout = [cent_dir '/lh.ec.z.wei.graph' num2str(n) '.' fsaverage '.nii.gz'];
%                 err = save_nifti(maskhdr_lh, fout);
%                 maskhdr_rh.vol = EC_rh; fout = [cent_dir '/rh.ec.z.wei.graph' num2str(n) '.' fsaverage '.nii.gz'];
%                 err = save_nifti(maskhdr_rh, fout);
                end
            end
            %page rank
            if cent_idx(4)
                disp(['Computing PC at correlation = ' num2str(r_thr(n)) ' ...'])
                %% bin
                tmppc = IPN_centPagerank(R_bin); 
                %raw
                tmp = tmppc;
                PC_lh = zeros(nVertices_lh,1); PC_rh = zeros(nVertices_rh,1); 
                PC_lh(idx_lh_mask) = tmp(1:nnz(idx_lh_mask));
                PC_rh(idx_rh_mask) = tmp(nnz(idx_lh_mask)+1:end);
                maskhdr_lh.vol = PC_lh; fout = [cent_dir '/lh.pc.bin.graph' num2str(n) '.' fsaverage '.nii.gz'];
                err = save_nifti(maskhdr_lh, fout);
                maskhdr_rh.vol = PC_rh; fout = [cent_dir '/rh.pc.bin.graph' num2str(n) '.' fsaverage '.nii.gz'];
                err = save_nifti(maskhdr_rh, fout);
                %z-score
%                 tmp = zscore(tmppc);
%                 PC_lh = zeros(nVertices_lh,1); PC_rh = zeros(nVertices_rh,1); 
%                 PC_lh(idx_lh_mask) = tmp(1:nnz(idx_lh_mask));
%                 PC_rh(idx_rh_mask) = tmp(nnz(idx_lh_mask)+1:end);
%                 maskhdr_lh.vol = PC_lh; fout = [cent_dir '/lh.pc.z.bin.graph' num2str(n) '.' fsaverage '.nii.gz'];
%                 err = save_nifti(maskhdr_lh, fout);
%                 maskhdr_rh.vol = PC_rh; fout = [cent_dir '/rh.pc.z.bin.graph' num2str(n) '.' fsaverage '.nii.gz'];
%                 err = save_nifti(maskhdr_rh, fout);
                %% weighted
                tmppc = IPN_centPagerank(R_wei); 
                %raw
                tmp = tmppc;
                PC_lh = zeros(nVertices_lh,1); PC_rh = zeros(nVertices_rh,1); 
                PC_lh(idx_lh_mask) = tmp(1:nnz(idx_lh_mask));
                PC_rh(idx_rh_mask) = tmp(nnz(idx_lh_mask)+1:end);
                maskhdr_lh.vol = PC_lh; fout = [cent_dir '/lh.pc.wei.graph' num2str(n) '.' fsaverage '.nii.gz'];
                err = save_nifti(maskhdr_lh, fout);
                maskhdr_rh.vol = PC_rh; fout = [cent_dir '/rh.pc.wei.graph' num2str(n) '.' fsaverage '.nii.gz'];
                err = save_nifti(maskhdr_rh, fout);
                %z-score
%                 tmp = zscore(tmppc);
%                 PC_lh = zeros(nVertices_lh,1); PC_rh = zeros(nVertices_rh,1); 
%                 PC_lh(idx_lh_mask) = tmp(1:nnz(idx_lh_mask));
%                 PC_rh(idx_rh_mask) = tmp(nnz(idx_lh_mask)+1:end);
%                 maskhdr_lh.vol = PC_lh; fout = [cent_dir '/lh.pc.z.wei.graph' num2str(n) '.' fsaverage '.nii.gz'];
%                 err = save_nifti(maskhdr_lh, fout);
%                 maskhdr_rh.vol = PC_rh; fout = [cent_dir '/rh.pc.z.wei.graph' num2str(n) '.' fsaverage '.nii.gz'];
%                 err = save_nifti(maskhdr_rh, fout);
            end
        end
    else
        err = 0;
    end
    if strcmp(savemat, 'true')
        save([cent_dir '/graphs.mat'], 'node_alone', 'r_thr', 'edge_density', 'adjMatrixB', 'adjMatrixW', '-v7.3')
    else
        save([cent_dir '/graphs.mat'], 'node_alone', 'r_thr', 'edge_density')
    end
end

end
