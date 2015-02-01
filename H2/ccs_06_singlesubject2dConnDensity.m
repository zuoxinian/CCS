function [densityRSFC_lh, densityRSFC_rh, rRSFC_lh, rRSFC_rh, densityRSFC_subcort, rRSFC_subcort] = ccs_06_singlesubject2dConnDensity( ana_dir, sub_list, rest_name, func_dir_name, seeds_name, seeds_hemi, fs_home, fsaverage, ccs_dir)
%CCS_06_SINGLESUBJECT2dConnDensity Computing the connection-density RSFC on the surface.
%   ana_dir -- full path of the analysis directory
%   sub_list -- full path of the list of subjects
%   rest_name -- the name of rest raw data (no extention)
%   func_dir_name -- the name of functional directory
%   seeds_name -- the seeds' name
%   seeds_hemi -- the seeds' hemipshere in
%   fs_home -- freesurfer home directory
%   fsaverage -- the fsaverage file name
%   ccs_dir -- the ccs home directory
%
% Author: Xi-Nian Zuo at IPCAS, Dec., 16, 2011.
% Author: Xi-Nian Zuo at IPCAS, Aug., 02, 2014.

if nargin < 9
    disp('Usage: ccs_06_singlesubject2dConnDensity( ana_dir, sub_list, rest_name, func_dir_name, seeds_name, seeds_hemi, fs_home, fsaverage, ccs_dir)')
    exit
end
%ifsmooth = 1; % use smoothed r-fmri data or unsmoothed data? default is smoothed data. 
subcort_labels = {'Amygdala','Caudate','Hippocampus','Accumbens-area',...
    'Pallidum','Putamen','Thalamus','Thalamus-Proper','Brain-Stem'};
fsLUT = importdata([ccs_dir '/matlab/etc/FreeSurferColorLUT.part']);
LUTdat = fsLUT.textdata; LUTstr = LUTdat(:,2); 
numSubcort = numel(subcort_labels);

%% FSAVERAGE: Searching labels in aparc.a2009s.annot
numSeeds = numel(seeds_name); 
fannot = [fs_home '/subjects/' fsaverage '/label/lh.aparc.a2009s.annot'];
[vertices_lh,label_lh,colortable_lh] = read_annotation(fannot);
struct_names_lh = colortable_lh.struct_names;
struct_labels_lh = colortable_lh.table;
nVertices_lh = numel(vertices_lh);
fannot = [fs_home '/subjects/' fsaverage '/label/rh.aparc.a2009s.annot'];
[vertices_rh,label_rh,colortable_rh] = read_annotation(fannot);
nVertices_rh = numel(vertices_rh);
struct_names_rh = colortable_rh.struct_names;
struct_labels_rh = colortable_rh.table;
clear fannot
%% SUBINFO
subs = importdata(sub_list); nsubs = numel(subs);
if ~iscell(subs)
    subs = num2cell(subs);
end
%% LOOP SUBJECTS
for k=1:nsubs
    if isnumeric(subs{k})
        disp(['Computing RSFC Density for subject ' num2str(subs{k}) ' ...'])
        func_dir = [ana_dir '/' num2str(subs{k}) '/' func_dir_name];
    else
        disp(['Computing RSFC Density for subject ' subs{k} ' ...'])
        func_dir = [ana_dir '/' subs{k} '/' func_dir_name];
    end
    rsfc_dir = [func_dir '/ConnDensity']; mask_dir = [func_dir '/mask'];
    if ~exist(rsfc_dir,'dir')
        mkdir(rsfc_dir); %Added in Nov 6, 2013.
    end
    rRSFC_subcort = zeros(2*numSubcort-1, numSeeds);
    densityRSFC_subcort = zeros(2*numSubcort-1, numSeeds);
    %aparc+aseg
    faparc_aseg = [func_dir '/segment/aparc.a2009s+aseg2func.nii.gz'];
    aparchdr = load_nifti(faparc_aseg); aparcvol = aparchdr.vol;
    aparcvec = reshape(aparcvol,numel(aparcvol),1);
    %vol mask
    fmask = [func_dir '/segment/global_mask.nii.gz'];
    maskhdr = load_nifti(fmask); maskvol = maskhdr.vol; 
    maskvec = reshape(maskvol,numel(maskvol),1);
    %vol bold (not smoothed)
    fname = [func_dir '/' rest_name '_pp_sm0.nii.gz'];
    boldhdr = load_nifti(fname); boldvol = boldhdr.vol;
    boldvec = reshape(boldvol,numel(maskvol),size(boldvol,4));
    subcort_ts = zeros(2*numSubcort-1, size(boldvol,4));
    for lid=1:numSubcort
        label = subcort_labels{lid};
        if lid<numSubcort
            %left hemi
            tmp_id = ccs_strfind(LUTstr, ['Left-' label]);
            label_val = str2double(LUTdat(tmp_id, 1));
            tmp_ts = boldvec((aparcvec.*maskvec)==label_val,:);
            %size(mean(tmp_ts)) %only for test
            subcort_ts(lid,:) = mean(tmp_ts); 
            %right hemi
            tmp_id = ccs_strfind(LUTstr, ['Right-' label]);
            label_val = str2double(LUTdat(tmp_id, 1));
            tmp_ts = boldvec((aparcvec.*maskvec)==label_val,:);
            subcort_ts(lid+numSubcort,:) = mean(tmp_ts);
        else
            tmp_id = ccs_strfind(LUTstr, label);
            label_val = str2double(LUTdat(tmp_id, 1));
            tmp_ts = boldvec((aparcvec.*maskvec)==label_val,:);
            subcort_ts(lid,:) = mean(tmp_ts);
        end
    end
    %lh
    fname = [func_dir '/' rest_name '.pp.sm6.' fsaverage '.lh.nii.gz'];
    tmphdr_lh = load_nifti(fname); vol_lh = squeeze(tmphdr_lh.vol); 
    %ntp = size(vol_lh,2) ;
    rRSFC_lh = zeros(nVertices_lh,numSeeds); densityRSFC_lh = zeros(nVertices_lh,numSeeds); 
    clear tmphdr_lh
    fmask = [mask_dir '/brain.' fsaverage '.lh.nii.gz'];
    maskhdr_lh = load_nifti(fmask); idx_lh_mask = find(maskhdr_lh.vol > 0);
    %rh
    fname = [func_dir '/' rest_name '.pp.sm6.' fsaverage '.rh.nii.gz'];
    tmphdr_rh = load_nifti(fname); vol_rh = squeeze(tmphdr_rh.vol);
    rRSFC_rh = zeros(nVertices_rh,numSeeds); densityRSFC_rh = zeros(nVertices_rh,numSeeds); 
    clear tmphdr_rh
    fmask = [mask_dir '/brain.' fsaverage '.rh.nii.gz'];
    maskhdr_rh = load_nifti(fmask); idx_rh_mask = find(maskhdr_rh.vol > 0);
    %seeds loop
    for n=1:numSeeds
        seed_name = seeds_name{n};
        seed_hemi = seeds_hemi{n};
        switch seed_hemi
            case 'lh'
                fseed = ['L-' seed_name]
                vertex_idx = intersect(find(label_lh == ...
                    struct_labels_lh(LFCD_matchstrCell(struct_names_lh,seed_name),5)), ...
                    idx_lh_mask);
            case 'rh'
                fseed = ['R-' seed_name]
                vertex_idx = intersect(find(label_rh == ...
                    struct_labels_rh(LFCD_matchstrCell(struct_names_rh,seed_name),5)), ...
                    idx_rh_mask);
            otherwise
                disp('Please assign the hemisphere for the seed.')
        end
        if ~isempty(vertex_idx)
            switch seed_hemi
            case 'lh'
                seed_ts = vol_lh(vertex_idx,:);
            case 'rh'
                seed_ts = vol_rh(vertex_idx,:);
            otherwise
                disp('Please assign the hemisphere for the seed.')
            end
            %subcortex
            tmpRSFC_subcort = IPN_fastCorr(subcort_ts', seed_ts');
            %choose r=0.20 as threshhold of significant correlation
            tmpBlock_subcort = zeros(size(tmpRSFC_subcort));
            %density of significant connectivity
            tmpBlock_subcort(tmpRSFC_subcort >= 0.2) = 1;
            densityRSFC_subcort(:, n) = sum(tmpBlock_subcort,2)/numel(vertex_idx);
            %strength of significant connectivity
            for lid=1:(2*numSubcort-1)
                tmpR = tmpRSFC_subcort(lid, :);
                idxR = find(tmpR >= 0.2);
                if ~isempty(idxR)
                    rRSFC_subcort(lid, n) = mean(tmpR(idxR));
                end
            end
            %Save Correlation Vectors
            fout = [rsfc_dir '/subcort.' fseed '.avgr.mat'];
            avgrVector = rRSFC_subcort(:, n); save(fout, 'avgrVector');
            %Save Density Vectors
            fout = [rsfc_dir '/subcort.' fseed '.rho.mat'];
            rhoVector = densityRSFC_subcort(:, n); save(fout, 'rhoVector');
            %cortex
            tmpRSFC_lh = IPN_fastCorr(vol_lh(idx_lh_mask,:)', seed_ts');
            tmpRSFC_rh = IPN_fastCorr(vol_rh(idx_rh_mask,:)', seed_ts');
            %choose r=0.20 as threshhold of significant correlation
            tmpBlock_lh = zeros(size(tmpRSFC_lh)); tmpBlock_rh = zeros(size(tmpRSFC_rh));
            %density of significant connectivity
            tmpBlock_lh(tmpRSFC_lh >= 0.2) = 1; tmpBlock_rh(tmpRSFC_rh >= 0.2) = 1;
            densityRSFC_lh(idx_lh_mask, n) = sum(tmpBlock_lh,2)/numel(vertex_idx);
            densityRSFC_rh(idx_rh_mask, n) = sum(tmpBlock_rh,2)/numel(vertex_idx);
            %strength of significant connectivity
            for vid=1:numel(idx_lh_mask)
                tmpR = tmpRSFC_lh(vid, :);
                idxR = find(tmpR >= 0.2);
                if ~isempty(idxR)
                    rRSFC_lh(idx_lh_mask(vid), n) = mean(tmpR(idxR));
                end
            end
            for vid=1:numel(idx_rh_mask)
                tmpR = tmpRSFC_rh(vid, :);
                idxR = find(tmpR >= 0.2);
                if ~isempty(idxR)
                    rRSFC_rh(idx_rh_mask(vid), n) = mean(tmpR(idxR));
                end
            end
            maskhdr_lh.datatype = 16; maskhdr_lh.descrip = ['CCS ' date];
            maskhdr_rh.datatype = 16; maskhdr_rh.descrip = ['CCS ' date];
            %Save Correlation Surfaces
            maskhdr_lh.vol = rRSFC_lh(:,n); 
            fout = [rsfc_dir '/lh.' fseed '.avgr.' fsaverage '.nii.gz'];
            err = save_nifti(maskhdr_lh, fout);
            maskhdr_rh.vol = rRSFC_rh(:,n); 
            fout = [rsfc_dir '/rh.' fseed '.avgr.' fsaverage '.nii.gz'];
            err = save_nifti(maskhdr_rh, fout);
            %Save Density Surfaces
            %lh
            maskhdr_lh.vol = densityRSFC_lh(:,n); 
            fout = [rsfc_dir '/lh.' fseed '.rho.' fsaverage '.nii.gz'];
            err = save_nifti(maskhdr_lh, fout);
            %rh
            maskhdr_rh.vol = densityRSFC_rh(:,n); 
            fout = [rsfc_dir '/rh.' fseed '.rho.' fsaverage '.nii.gz'];
            err = save_nifti(maskhdr_rh, fout);
        else
            disp('Please select a target seed name from aparc.a2009s in FreeSurfer.')
        end
    end
end

