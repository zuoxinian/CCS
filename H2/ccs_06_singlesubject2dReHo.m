function [cReHo_lh, cReHo_rh, zReHo_lh, zReHo_rh] = ccs_06_singlesubject2dReHo( ana_dir, ...
    sub_list, rest_name, func_dir_name, fsaverage, fs_vertex_adj, neighbor_type)
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
% Modified by Xi-Nian Zuo at IPCAS, Dec., 18, 2016.

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
    surfts_lh = squeeze(surfPPhdr_lh.vol)';
    if neighbor_type == 2
        tmp_nbrs = lh_nbrs2;
    else
        tmp_nbrs = lh_nbrs;
    end
    [cReHo_lh, zReHo_lh] = ccs_ReHo(surfts_lh,tmp_nbrs);
    %rh
    fname = [func_dir '/' rest_name '.pp.sm0.' fsaverage '.rh.nii.gz'];
    surfPPhdr_rh = load_nifti(fname);
    surfts_rh = squeeze(surfPPhdr_rh.vol)';
    if neighbor_type == 2
        tmp_nbrs = rh_nbrs2;
    else
        tmp_nbrs = rh_nbrs;
    end
    [cReHo_rh, zReHo_rh] = ccs_ReHo(surfts_rh,tmp_nbrs);
   
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
    err1 = save_nifti(surfMASKhdr_lh, fout);
    %rh
    surfMASKhdr_rh.vol = cReHo_rh; 
    if neighbor_type == 2
        fout = [reho_dir '/rh.reho2.' fsaverage '.nii.gz'];
    else
        fout = [reho_dir '/rh.reho.' fsaverage '.nii.gz'];
    end
    err2 = save_nifti(surfMASKhdr_rh, fout);
    
    %% Save ReHo Z
    %lh
    surfMASKhdr_lh.vol = zReHo_lh; 
    if neighbor_type == 2
        fout = [reho_dir '/lh.reho2.z.' fsaverage '.nii.gz'];
    else
        fout = [reho_dir '/lh.reho.z.' fsaverage '.nii.gz'];
    end
    err3 = save_nifti(surfMASKhdr_lh, fout);
    %rh
    surfMASKhdr_rh.vol = zReHo_rh;
    if neighbor_type == 2
        fout = [reho_dir '/rh.reho2.z.' fsaverage '.nii.gz'];
    else
        fout = [reho_dir '/rh.reho.z.' fsaverage '.nii.gz'];
    end
    err4 = save_nifti(surfMASKhdr_rh, fout);
    
end

