function [rRSFC_lh, rRSFC_rh] = ccs_06_singlesubject2dSFC( ana_dir, ...
    sub_list, rest_name, func_dir_name, seeds_name, seeds_hemi, ...
    ccs_home, fsaverage)
%CCS_06_SINGLESUBJECT2dSFC Computing the RSFC on the surface.
%   ana_dir -- full path of the analysis directory
%   sub_list -- full path of the list of subjects
%   rest_name -- the name of rest raw data (no extention)
%   func_dir_name -- the name of functional directory
%   seeds_name -- the seeds' name
%   seeds_hemi -- the seeds' hemipshere in
%   ccs_home -- the ccs home directory
%   fsaverage -- the fsaverage file name
%
%   Note: need to add different ways of define seed regions.

% Author: Xi-Nian Zuo at IPCAS, Dec., 16, 2011.
% Modified: Xi-Nian Zuo at IPCAS, Dec., 28, 2015.

if nargin < 8
    disp('Usage: ccs_06_singlesubject2dSFC( ana_dir, sub_list, rest_name, func_dir_name, fannot, seeds_name, seeds_hemi, ccs_home, fsaverage)')
    exit
end
ifsmooth = 1; % use smoothed r-fmri data or unsmoothed data? default is smoothed data. 
%% FSAVERAGE: Searching labels in aparc.a2009s.annot
numSeeds = numel(seeds_name); 
fannot = [ccs_home '/parcellation/ParcelsYeo2011/' fsaverage ...
    '/lh.Yeo2011_17Networks_N1000.split_components.annot'];
[vertices_lh,label_lh,colortable_lh] = read_annotation(fannot);
struct_names_lh = colortable_lh.struct_names;
struct_labels_lh = colortable_lh.table;
nVertices_lh = numel(vertices_lh);
fannot = [ccs_home '/parcellation/ParcelsYeo2011/' fsaverage ...
    '/rh.Yeo2011_17Networks_N1000.split_components.annot'];
[vertices_rh,label_rh,colortable_rh] = read_annotation(fannot);
nVertices_rh = numel(vertices_rh);
struct_names_rh = colortable_rh.struct_names;
struct_labels_rh = colortable_rh.table;
clear fannot
%% SUBINFO
fid = fopen(sub_list);
tmpcell = textscan(fid, '%s'); 
fclose(fid);
subs = tmpcell{1} ; nsubs = numel(subs);
%% LOOP SUBJECTS
for k=1:nsubs
    if isnumeric(subs{k}) %Modified in Oct 28, 2015.
        disp(['Computing seedFC for subject ' num2str(subs{k}) ' ...'])
        func_dir = [ana_dir '/' num2str(subs{k}) '/' func_dir_name];
    else
        disp(['Computing seedFC for subject ' subs{k} ' ...'])
        func_dir = [ana_dir '/' subs{k} '/' func_dir_name];
    end
    rsfc_dir = [func_dir '/seedFC']; mask_dir = [func_dir '/mask'];
    if ~exist(rsfc_dir,'dir')
        mkdir(rsfc_dir); %Added in Nov 6, 2013.
    end
    %lh
    if ifsmooth
        fname = [func_dir '/' rest_name '.pp.sm6.' fsaverage '.lh.nii.gz'];
    else
        fname = [func_dir '/' rest_name '.pp.sm0.' fsaverage '.lh.nii.gz'];
    end
    tmphdr_lh = load_nifti(fname); vol_lh = squeeze(tmphdr_lh.vol); 
    ntp = size(vol_lh,2) ;
    rRSFC_lh = zeros(nVertices_lh,1); clear tmphdr_lh
    fmask = [mask_dir '/brain.' fsaverage '.lh.nii.gz'];
    maskhdr_lh = load_nifti(fmask); idx_lh_mask = (maskhdr_lh.vol > 0);
    %rh
    if ifsmooth
        fname = [func_dir '/' rest_name '.pp.sm6.' fsaverage '.rh.nii.gz'];
    else
        fname = [func_dir '/' rest_name '.pp.sm0.' fsaverage '.rh.nii.gz'];
    end
    tmphdr_rh = load_nifti(fname); vol_rh = squeeze(tmphdr_rh.vol);
    rRSFC_rh = zeros(nVertices_rh,1); clear tmphdr_rh
    fmask = [mask_dir '/brain.' fsaverage '.rh.nii.gz'];
    maskhdr_rh = load_nifti(fmask); idx_rh_mask = (maskhdr_rh.vol > 0);
    %seeds loop
    for seedID=1:numSeeds
        seed_name = seeds_name{seedID,1};
        seed_hemi = seeds_hemi{seedID,1};
        switch seed_hemi
            case 'lh'
                vertex_idx = find(label_lh == ...
                    struct_labels_lh(LFCD_matchstrCell(struct_names_lh,...
                    seed_name),5));
            case 'rh'
                vertex_idx = find(label_rh == ...
                    struct_labels_rh(LFCD_matchstrCell(struct_names_rh,...
                    seed_name),5));
            otherwise
                disp('Please assign the hemisphere for the seed.')
        end
        if ~isempty(vertex_idx)
            switch seed_hemi
            case 'lh'
                seed_ts = mean(vol_lh(vertex_idx,:));
            case 'rh'
                seed_ts = mean(vol_rh(vertex_idx,:));
            otherwise
                disp('Please assign the hemisphere for the seed.')
            end
            rRSFC_lh(idx_lh_mask) = ccs_core_fastCoRR(vol_lh(idx_lh_mask,:)', seed_ts');
            rRSFC_rh(idx_rh_mask) = ccs_core_fastCoRR(vol_rh(idx_rh_mask,:)', seed_ts');
            maskhdr_lh.datatype = 16; maskhdr_lh.descrip = ['CCS ' date];
            maskhdr_rh.datatype = 16; maskhdr_rh.descrip = ['CCS ' date];
            %Save Correlation Surfaces
            maskhdr_lh.vol = rRSFC_lh; 
            fout = [rsfc_dir '/lh.' seed_name '.r.' fsaverage '.nii.gz'];
            err = save_nifti(maskhdr_lh, fout);
            maskhdr_rh.vol = rRSFC_rh; 
            fout = [rsfc_dir '/rh.' seed_name '.r.' fsaverage '.nii.gz'];
            err = save_nifti(maskhdr_rh, fout);
            %Save Fisher-Z Surfaces
            %lh
            rRSFC_lh_adj = rRSFC_lh; 
            rRSFC_lh_adj(rRSFC_lh==1) = 1-eps(0);%avoid INF in final z-maps
            rRSFC_lh_adj(rRSFC_lh==-1) = -1+eps(0);%avoid INF in final z-maps
            tmp = zeros(size(rRSFC_lh)); 
            tmp(idx_lh_mask) = atanh(rRSFC_lh_adj(idx_lh_mask));
            maskhdr_lh.vol = tmp; 
            fout = [rsfc_dir '/lh.' seed_name '.z.' fsaverage '.nii.gz'];
            err = save_nifti(maskhdr_lh, fout);
            %rh
            rRSFC_rh_adj = rRSFC_rh; 
            rRSFC_rh_adj(rRSFC_rh==1) = 1-eps(0);
            rRSFC_rh_adj(rRSFC_rh==-1) = -1+eps(0);
            tmp = zeros(size(rRSFC_rh)) ; 
            tmp(idx_rh_mask) = atanh(rRSFC_rh_adj(idx_rh_mask));
            maskhdr_rh.vol = tmp; 
            fout = [rsfc_dir '/rh.' seed_name '.z.' fsaverage '.nii.gz'];
            err = save_nifti(maskhdr_rh, fout);
            %Save Z-stat Surfaces
            %lh
            tmp = zeros(size(rRSFC_lh)) ; 
            tmp(idx_lh_mask) = sqrt(ntp-3)*atanh(rRSFC_lh_adj(idx_lh_mask));
            maskhdr_lh.vol = tmp; 
            fout = [rsfc_dir '/lh.' seed_name '.zstat.' fsaverage '.nii.gz'];
            err = save_nifti(maskhdr_lh, fout);
            %rh
            tmp = zeros(size(rRSFC_rh)) ; 
            tmp(idx_rh_mask) = sqrt(ntp-3)*atanh(rRSFC_rh_adj(idx_rh_mask));
            maskhdr_rh.vol = tmp; 
            fout = [rsfc_dir '/rh.' seed_name '.zstat.' fsaverage '.nii.gz'];
            err = save_nifti(maskhdr_rh, fout);
        else
            disp('Please select a seed name from Yeo2011_17Networks_N1000.split_components.')
        end
    end
end

