function [cReHo_lh, cReHo_rh] = ccs_06_singlesubject2dReHo( ana_dir, sub_list, rest_name, ...
    func_dir_name, fsaverage, fs_vertex_adj, neighbor_type)
%CCS_06_SINGLESUBJECT2dREHO Computing the ReHo on the surface.
%   ana_dir -- full path of the analysis directory
%   sub_list -- full path of the list of subjects
%   rest_name -- the name of rest raw data (no extention)
%   func_dir_name -- the name of functional directory
%   fsaverage -- the fsaverage file name
%   fs_vertex_adj -- the adjacency matrix of fs vertices
%   neighbor_type -- the type of a vertex's neighbors (1 - length-one, 2 - length-two)

% Author: Xi-Nian Zuo at IPCAS, Dec., 14, 2011.
% Modified by Xi-Nian Zuo at IPCAS, Aug., 5, 2012.
% Modified by Xi-Nian Zuo at IPCAS, Sept., 22, 2013.
% Modified by Xi-Nian Zuo at IPCAS, Nov., 15, 2014.

if nargin < 7
    disp('Usage: ccs_06_singlesubject2dReHo( ana_dir, sub_list, rest_name, func_dir_name, fsaverage, fs_vertex_adj, neighbor_type)')
    exit
end
%% FSAVERAGE
load(fs_vertex_adj)
%% SUBINFO
fid = fopen(sub_list) ;
tmpcell = textscan(fid, '%s'); 
fclose(fid);
subs = tmpcell{1} ; nsubs = numel(subs);
%% LOOP SUBJECTS
for k=1:nsubs
    if isnumeric(subs{k})
        disp(['Computing ReHo for subject ' num2str(subs{k}) ' ...'])
        func_dir = [ana_dir '/' num2str(subs{k}) '/' func_dir_name];
    else
        disp(['Computing ReHo for subject ' subs{k} ' ...'])
        func_dir = [ana_dir '/' subs{k} '/' func_dir_name];
    end
    reho_dir = [func_dir '/ReHo']; 
    if ~exist(reho_dir,'dir')
        mkdir(reho_dir); %Added in Nov 18, 2012.
    end
    mask_dir = [func_dir '/mask'];
    %% Computation
    %lh
    fname = [func_dir '/' rest_name '.pp.sm0.' fsaverage '.lh.nii.gz'];
    surfPPhdr_lh = load_nifti(fname);
    cReHo_lh = zeros(nVertices_lh,1); 
    for ii=1:nVertices_lh
        if ~mod(ii,500); 
            disp(['Completing ' num2str(ii/nVertices_lh*100) ...
            ' percent vertices processed in left hemisphere ...'])
        end
        tmp_ts = squeeze(surfPPhdr_lh.vol(ii,1,1,:));
        if std(tmp_ts) > 0 
            if neighbor_type == 2
                tmp_nbrs = lh_nbrs2{ii};
            else
                tmp_nbrs = lh_nbrs{ii};
            end
            nbrs_ts = squeeze(surfPPhdr_lh.vol(tmp_nbrs,1,1,:));% total 7/20 or 6/19 neighbor vertices
            ts = [tmp_ts nbrs_ts(std(nbrs_ts,1,2)>0,:)']; 
            [n,m] = size(ts); [~,I]=sort(ts); [~,R]=sort(I);
            S=sum(sum(R,2).^2)-n*mean(sum(R,2)).^2;
            F=m*m*(n*n*n-n); cReHo_lh(ii)=12*S/F;
        end
    end
    %rh
    fname = [func_dir '/' rest_name '.pp.sm0.' fsaverage '.rh.nii.gz'];
    surfPPhdr_rh = load_nifti(fname);
    cReHo_rh = zeros(nVertices_rh,1);
    for ii=1:nVertices_rh
        if ~mod(ii,500); 
            disp(['Completing ' num2str(ii/nVertices_rh*100) ...
            ' percent vertices processed in right hemisphere ...'])
        end
        tmp_ts = squeeze(surfPPhdr_rh.vol(ii,1,1,:));
        if std(tmp_ts) > 0
            if neighbor_type == 2
                tmp_nbrs = rh_nbrs2{ii};
            else
                tmp_nbrs = rh_nbrs{ii};
            end
            nbrs_ts = squeeze(surfPPhdr_rh.vol(tmp_nbrs,1,1,:));
            ts = [tmp_ts nbrs_ts(std(nbrs_ts,1,2)>0,:)']; 
            [n,m] = size(ts); [~,I]=sort(ts); [~,R]=sort(I);
            S=sum(sum(R,2).^2)-n*mean(sum(R,2)).^2;
            F=m*m*(n*n*n-n); cReHo_rh(ii)=12*S/F;
        end
    end
    %% Surface Masks
    %lh
    fmask = [mask_dir '/brain.' fsaverage '.lh.nii.gz'];
    surfMASKhdr_lh = load_nifti(fmask); %idx_lh_mask = find(surfMASKhdr_lh.vol > 0);
    surfMASKhdr_lh.datatype = 16; %float
    surfMASKhdr_lh.descrip = ['CCS ' date];
    %rh
    fmask = [mask_dir '/brain.' fsaverage '.rh.nii.gz'];
    surfMASKhdr_rh = load_nifti(fmask); %idx_rh_mask = find(surfMASKhdr_rh.vol > 0);
    surfMASKhdr_rh.datatype = 16; %float
    surfMASKhdr_rh.descrip = ['CCS ' date];
    %% Save ReHo
    %lh
    surfMASKhdr_lh.vol = cReHo_lh; 
    if neighbor_type == 2
        fout = [reho_dir '/lh.reho2.' fsaverage '.nii.gz'];
    else
        fout = [reho_dir '/lh.reho.' fsaverage '.nii.gz'];
    end
    err = save_nifti(surfMASKhdr_lh, fout);
    %rh
    surfMASKhdr_rh.vol = cReHo_rh; 
    if neighbor_type == 2
        fout = [reho_dir '/rh.reho2.' fsaverage '.nii.gz'];
    else
        fout = [reho_dir '/rh.reho.' fsaverage '.nii.gz'];
    end
    err = save_nifti(surfMASKhdr_rh, fout);
%     %% Save ReHo Z
%     tmp_bh = [cReHo_lh(idx_lh_mask) ; cReHo_rh(idx_rh_mask)];
%     mean_reho = mean(tmp_bh);
%     std_reho = std(tmp_bh);
%     if neighbor_type == 2
%         fout = [reho_dir '/reho2.mean.' fsaverage '.txt'];
%     else
%         fout = [reho_dir '/reho.mean.' fsaverage '.txt'];
%     end
%     save(fout,'mean_reho','-ascii');
%     if neighbor_type == 2
%         fout = [reho_dir '/reho2.std.' fsaverage '.txt'];
%     else
%         fout = [reho_dir '/reho.std.' fsaverage '.txt'];
%     end
%     save(fout,'std_reho','-ascii');
%     %lh
%     tmp = zeros(size(cReHo_lh)) ; 
%     tmp(idx_lh_mask) = (cReHo_lh(idx_lh_mask)-mean_reho)/std_reho;
%     surfMASKhdr_lh.vol = tmp; 
%     if neighbor_type == 2
%         fout = [reho_dir '/lh.reho2.z.' fsaverage '.nii.gz'];
%     else
%         fout = [reho_dir '/lh.reho.z.' fsaverage '.nii.gz'];
%     end
%     err = save_nifti(surfMASKhdr_lh, fout);
%     %rh
%     tmp = zeros(size(cReHo_rh)) ; 
%     tmp(idx_rh_mask) = (cReHo_rh(idx_rh_mask)-mean_reho)/std_reho;
%     surfMASKhdr_rh.vol = tmp;
%     if neighbor_type == 2
%         fout = [reho_dir '/rh.reho2.z.' fsaverage '.nii.gz'];
%     else
%         fout = [reho_dir '/rh.reho.z.' fsaverage '.nii.gz'];
%     end
%     err = save_nifti(surfMASKhdr_rh, fout);
end

