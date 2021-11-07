function [cALFF_lh, cALFF_rh, cFALFF_lh, cFALFF_rh] = ccs_06_singlesubject2dALFF( ana_dir, sub_list, rest_name, ...
    tr, func_dir_name, fs_home, fsaverage)
%CCS_06_SINGLESUBJECTALFF_SURF Computing the ALFF/FALFF on the surface.
%   ana_dir -- full path of the analysis directory
%   sub_list -- full path of the list of subjects
%   rest_name -- the name of rest raw data (no extention)
%   tr -- time repetition
%   func_dir_name -- the name of functional directory
%   fsaverage -- the fsaverage file name
%   fs_home -- freesurfer home directory
%
%   Note: need to double check the usage of LFCD_alff.m function and
%   compare the outputs with volume-based findings. Pay special attention
%   to the changes of TS introduced by mri_vol2surf command.

% Author: Xi-Nian Zuo at IPCAS, Dec., 14, 2011.
% Modified: Xi-Nian Zuo at IPCAS, Sept., 22, 2013.
% Modified: Xi-Nian Zuo at IPCAS, Aug., 02, 2014.
% Modified: Xi-Nian Zuo at IPCAS, Nov., 15, 2014.

if nargin < 7
    disp('Usage: ccs_06_singlesubject2dALFF( ana_dir, sub_list, rest_name, tr, func_dir_name, fs_home, fsaverage)')
    exit
end
%% FSAVERAGE
avgSurf = {[fs_home '/subjects/' fsaverage '/surf/lh.pial'], ...
           [fs_home '/subjects/' fsaverage '/surf/rh.pial']};
%Left Hemisphere
[vertices, ~] = freesurfer_read_surf(avgSurf{1});
nVertices_lh = size(vertices,1) ;
%Right Hemisphere
[vertices, ~] = freesurfer_read_surf(avgSurf{2});
nVertices_rh = size(vertices,1) ;
clear nVertices
%% SUBINFO
fid = fopen(sub_list) ;
tmpcell = textscan(fid, '%s'); 
fclose(fid);
subs = tmpcell{1} ; 
nsubs = numel(subs);
%% LOOP SUBJECTS
for k=1:nsubs
    if isnumeric(subs{k})
        disp(['Computing ALFF/FALFF for subject ' num2str(subs{k}) ' ...'])
        func_dir = [ana_dir '/' num2str(subs{k}) '/' func_dir_name];
    else
        disp(['Computing ALFF/FALFF for subject ' subs{k} ' ...'])
        func_dir = [ana_dir '/' subs{k} '/' func_dir_name];
    end
    alff_dir = [func_dir '/ALFF'];
    if ~exist(alff_dir,'dir')
         mkdir(alff_dir);
    end
    mask_dir = [func_dir '/mask'];
    %lh
    fmask = [mask_dir '/brain.' fsaverage '.lh.nii.gz'];
    surfMASKhdr_lh = load_nifti(fmask); %idx_lh_mask = find(surfMASKhdr_lh.vol > 0);
    surfMASKhdr_lh.datatype = 16; %float
    surfMASKhdr_lh.descrip = ['CCS ' date];
    fwhm = [0 6];
    for smid=1:2
        fname = [func_dir '/' rest_name '.pp.nofilt.sm' num2str(fwhm(smid)) '.' fsaverage '.lh.nii.gz'];% no smoothing
        surfPPhdr_lh = load_nifti(fname);
        %Amplitude
        cALFF_lh = zeros(nVertices_lh,1); cFALFF_lh = zeros(nVertices_lh,1);
        cALFFs4_lh = zeros(nVertices_lh,1); cFALFFs4_lh = zeros(nVertices_lh,1);
        %Phase (degree)
        cPLFF_lh = zeros(nVertices_lh,1); cFPLFF_lh = zeros(nVertices_lh,1);
        cPLFFs4_lh = zeros(nVertices_lh,1); cFPLFFs4_lh = zeros(nVertices_lh,1);
        for ii=1:nVertices_lh
            if ~mod(ii,500) 
                disp(['Completing ' num2str(ii/nVertices_lh*100) ...
                ' percent vertices processed in left hemisphere ...'])
            end
            tmp_ts = squeeze(surfPPhdr_lh.vol(ii,1,1,:));
            if std(tmp_ts) > 0
                [ cALFF_lh(ii), cFALFF_lh(ii), cPLFF_lh(ii), cFPLFF_lh(ii) ] = LFCD_alff(tmp_ts, tr, 0.01, 0.1);
                [ cALFFs4_lh(ii), cFALFFs4_lh(ii), cPLFFs4_lh(ii), cFPLFFs4_lh(ii) ] = LFCD_alff(tmp_ts, tr, 0.027, 0.073);
            end
        end
        %ALFF
        surfMASKhdr_lh.vol = cALFF_lh; 
        fout = [alff_dir '/lh.alff.sm' num2str(fwhm(smid)) '.' fsaverage '.nii.gz'];
        err = save_nifti(surfMASKhdr_lh, fout);
%         tmp = zeros(size(cALFF_lh)) ; tmp(idx_lh_mask) = zscore(cALFF_lh(idx_lh_mask));
%         surfMASKhdr_lh.vol = tmp; fout = [alff_dir '/lh.alff.z.sm' num2str(fwhm) '.' fsaverage '.nii.gz'];
%         err = save_nifti(surfMASKhdr_lh, fout);
        %ALFF slow4
        surfMASKhdr_lh.vol = cALFFs4_lh; 
        fout = [alff_dir '/lh.alff.slow4.sm' num2str(fwhm(smid)) '.' fsaverage '.nii.gz'];
        err = save_nifti(surfMASKhdr_lh, fout);
%         tmp = zeros(size(cALFF_lh)) ; tmp(idx_lh_mask) = zscore(cALFFs4_lh(idx_lh_mask));
%         surfMASKhdr_lh.vol = tmp; fout = [alff_dir '/lh.alff.slow4.z.sm' num2str(fwhm) '.' fsaverage '.nii.gz'];
%         err = save_nifti(surfMASKhdr_lh, fout);
        %PLFF
%         surfMASKhdr_lh.vol = cPLFF_lh; fout = [alff_dir '/lh.plff.sm' num2str(fwhm) '.' fsaverage '.nii.gz'];
%         err = save_nifti(surfMASKhdr_lh, fout);
%         tmp = zeros(size(cPLFF_lh)) ; tmp(idx_lh_mask) = zscore(cPLFF_lh(idx_lh_mask));
%         surfMASKhdr_lh.vol = tmp; fout = [alff_dir '/lh.plff.z.sm' num2str(fwhm) '.' fsaverage '.nii.gz'];
%         err = save_nifti(surfMASKhdr_lh, fout);
        %PLFF slow4
%         surfMASKhdr_lh.vol = cPLFFs4_lh; fout = [alff_dir '/lh.plff.slow4.sm' num2str(fwhm) '.' fsaverage '.nii.gz'];
%         err = save_nifti(surfMASKhdr_lh, fout);
%         tmp = zeros(size(cPLFF_lh)) ; tmp(idx_lh_mask) = zscore(cPLFFs4_lh(idx_lh_mask));
%         surfMASKhdr_lh.vol = tmp; fout = [alff_dir '/lh.plff.slow4.z.sm' num2str(fwhm) '.' fsaverage '.nii.gz'];
%         err = save_nifti(surfMASKhdr_lh, fout);
        %FALFF
        surfMASKhdr_lh.vol = cFALFF_lh; 
        fout = [alff_dir '/lh.falff.sm' num2str(fwhm(smid)) '.' fsaverage '.nii.gz'];
        err = save_nifti(surfMASKhdr_lh, fout);
%         tmp = zeros(size(cFALFF_lh)) ; tmp(idx_lh_mask) = zscore(cFALFF_lh(idx_lh_mask));
%         surfMASKhdr_lh.vol = tmp; fout = [alff_dir '/lh.falff.z.sm' num2str(fwhm) '.' fsaverage '.nii.gz'];
%         err = save_nifti(surfMASKhdr_lh, fout);
        %FALFF slow4
        surfMASKhdr_lh.vol = cFALFFs4_lh; 
        fout = [alff_dir '/lh.falff.slow4.sm' num2str(fwhm(smid)) '.' fsaverage '.nii.gz'];
        err = save_nifti(surfMASKhdr_lh, fout);
%         tmp = zeros(size(cFALFF_lh)) ; tmp(idx_lh_mask) = zscore(cFALFFs4_lh(idx_lh_mask));
%         surfMASKhdr_lh.vol = tmp; fout = [alff_dir '/lh.falff.slow4.z.sm' num2str(fwhm) '.' fsaverage '.nii.gz'];
%         err = save_nifti(surfMASKhdr_lh, fout);
        %FPLFF
%         surfMASKhdr_lh.vol = cFPLFF_lh; fout = [alff_dir '/lh.fplff.sm' num2str(fwhm) '.' fsaverage '.nii.gz'];
%         err = save_nifti(surfMASKhdr_lh, fout);
%         tmp = zeros(size(cFPLFF_lh)) ; tmp(idx_lh_mask) = zscore(cFPLFF_lh(idx_lh_mask));
%         surfMASKhdr_lh.vol = tmp; fout = [alff_dir '/lh.fplff.z.sm' num2str(fwhm) '.' fsaverage '.nii.gz'];
%         err = save_nifti(surfMASKhdr_lh, fout);
        %FPLFF slow4
%         surfMASKhdr_lh.vol = cFPLFFs4_lh; fout = [alff_dir '/lh.fplff.slow4.sm' num2str(fwhm) '.' fsaverage '.nii.gz'];
%         err = save_nifti(surfMASKhdr_lh, fout);
%         tmp = zeros(size(cFPLFF_lh)) ; tmp(idx_lh_mask) = zscore(cFPLFFs4_lh(idx_lh_mask));
%         surfMASKhdr_lh.vol = tmp; fout = [alff_dir '/lh.fplff.slow4.z.sm' num2str(fwhm) '.' fsaverage '.nii.gz'];
%         err = save_nifti(surfMASKhdr_lh, fout);
    end
    %rh
    fmask = [mask_dir '/brain.' fsaverage '.rh.nii.gz'];
    surfMASKhdr_rh = load_nifti(fmask); %idx_rh_mask = find(surfMASKhdr_rh.vol > 0);
    surfMASKhdr_rh.datatype = 16; %float
    surfMASKhdr_rh.descrip = ['CCS ' date];
    for smid=1:2
        fname = [func_dir '/' rest_name '.pp.nofilt.sm' num2str(fwhm(smid)) '.' fsaverage '.rh.nii.gz'];
        surfPPhdr_rh = load_nifti(fname);
        %amplitude
        cALFF_rh = zeros(nVertices_rh,1); cFALFF_rh = zeros(nVertices_rh,1);
        cALFFs4_rh = zeros(nVertices_rh,1); cFALFFs4_rh = zeros(nVertices_rh,1);
        %phase
        cPLFF_rh = zeros(nVertices_rh,1); cFPLFF_rh = zeros(nVertices_rh,1);
        cPLFFs4_rh = zeros(nVertices_rh,1); cFPLFFs4_rh = zeros(nVertices_rh,1);
        for ii=1:nVertices_rh
            if ~mod(ii,500) 
                disp(['Completing ' num2str(ii/nVertices_rh*100) ...
                ' percent vertices processed in right hemisphere ...'])
            end
            tmp_ts = squeeze(surfPPhdr_rh.vol(ii,1,1,:));
            if std(tmp_ts) > 0
                [ cALFF_rh(ii), cFALFF_rh(ii), cPLFF_rh(ii), cFPLFF_rh(ii) ] = LFCD_alff(tmp_ts, tr, 0.01, 0.1);
                [ cALFFs4_rh(ii), cFALFFs4_rh(ii), cPLFFs4_rh(ii), cFPLFFs4_rh(ii)] = LFCD_alff(tmp_ts, tr, 0.027, 0.073);
            end
        end
        %ALFF
        surfMASKhdr_rh.vol = cALFF_rh; 
        fout = [alff_dir '/rh.alff.sm' num2str(fwhm(smid)) '.' fsaverage '.nii.gz'];
        err = save_nifti(surfMASKhdr_rh, fout);
%         tmp = zeros(size(cALFF_rh)) ; tmp(idx_rh_mask) = zscore(cALFF_rh(idx_rh_mask));
%         surfMASKhdr_rh.vol = tmp; fout = [alff_dir '/rh.alff.z.sm' num2str(fwhm) '.' fsaverage '.nii.gz'];
%         err = save_nifti(surfMASKhdr_rh, fout);
        %ALFF slow4
        surfMASKhdr_rh.vol = cALFFs4_rh; 
        fout = [alff_dir '/rh.alff.slow4.sm' num2str(fwhm(smid)) '.' fsaverage '.nii.gz'];
        err = save_nifti(surfMASKhdr_rh, fout);
%         tmp = zeros(size(cALFF_rh)) ; tmp(idx_rh_mask) = zscore(cALFFs4_rh(idx_rh_mask));
%         surfMASKhdr_rh.vol = tmp; fout = [alff_dir '/rh.alff.slow4.z.sm' num2str(fwhm) '.' fsaverage '.nii.gz'];
%         err = save_nifti(surfMASKhdr_rh, fout);
        %PLFF
%         surfMASKhdr_rh.vol = cPLFF_rh; fout = [alff_dir '/rh.plff.sm' num2str(fwhm) '.' fsaverage '.nii.gz'];
%         err = save_nifti(surfMASKhdr_rh, fout);
%         tmp = zeros(size(cPLFF_rh)) ; tmp(idx_rh_mask) = zscore(cPLFF_rh(idx_rh_mask));
%         surfMASKhdr_rh.vol = tmp; fout = [alff_dir '/rh.plff.z.sm' num2str(fwhm) '.' fsaverage '.nii.gz'];
%         err = save_nifti(surfMASKhdr_rh, fout);
        %PLFF slow4
%         surfMASKhdr_rh.vol = cPLFFs4_rh; fout = [alff_dir '/rh.plff.slow4.sm' num2str(fwhm) '.' fsaverage '.nii.gz'];
%         err = save_nifti(surfMASKhdr_rh, fout);
%         tmp = zeros(size(cPLFF_rh)) ; tmp(idx_rh_mask) = zscore(cPLFFs4_rh(idx_rh_mask));
%         surfMASKhdr_rh.vol = tmp; fout = [alff_dir '/rh.plff.slow4.z.sm' num2str(fwhm) '.' fsaverage '.nii.gz'];
%         err = save_nifti(surfMASKhdr_rh, fout);
        %FALFF
        surfMASKhdr_rh.vol = cFALFF_rh; 
        fout = [alff_dir '/rh.falff.sm' num2str(fwhm(smid)) '.' fsaverage '.nii.gz'];
        err = save_nifti(surfMASKhdr_rh, fout);
%         tmp = zeros(size(cFALFF_rh)) ; tmp(idx_rh_mask) = zscore(cFALFF_rh(idx_rh_mask));
%         surfMASKhdr_rh.vol = tmp; fout = [alff_dir '/rh.falff.z.sm' num2str(fwhm) '.' fsaverage '.nii.gz'];
%         err = save_nifti(surfMASKhdr_rh, fout);
        %FALFF slow4
        surfMASKhdr_rh.vol = cFALFFs4_rh; 
        fout = [alff_dir '/rh.falff.slow4.sm' num2str(fwhm(smid)) '.' fsaverage '.nii.gz'];
        err = save_nifti(surfMASKhdr_rh, fout);
%         tmp = zeros(size(cFALFF_rh)) ; tmp(idx_rh_mask) = zscore(cFALFFs4_rh(idx_rh_mask));
%         surfMASKhdr_rh.vol = tmp; fout = [alff_dir '/rh.falff.slow4.z.sm' num2str(fwhm) '.' fsaverage '.nii.gz'];
%         err = save_nifti(surfMASKhdr_rh, fout);
        %FPLFF
%         surfMASKhdr_rh.vol = cFPLFF_rh; fout = [alff_dir '/rh.fplff.sm' num2str(fwhm) '.' fsaverage '.nii.gz'];
%         err = save_nifti(surfMASKhdr_rh, fout);
%         tmp = zeros(size(cFPLFF_rh)) ; tmp(idx_rh_mask) = zscore(cFPLFF_rh(idx_rh_mask));
%         surfMASKhdr_rh.vol = tmp; fout = [alff_dir '/rh.fplff.z.sm' num2str(fwhm) '.' fsaverage '.nii.gz'];
%         err = save_nifti(surfMASKhdr_rh, fout);
        %FPLFF slow4
%         surfMASKhdr_rh.vol = cFPLFFs4_rh; fout = [alff_dir '/rh.fplff.slow4.sm' num2str(fwhm) '.' fsaverage '.nii.gz'];
%         err = save_nifti(surfMASKhdr_rh, fout);
%         tmp = zeros(size(cFPLFF_rh)) ; tmp(idx_rh_mask) = zscore(cFPLFFs4_rh(idx_rh_mask));
%         surfMASKhdr_rh.vol = tmp; fout = [alff_dir '/rh.fplff.slow4.z.sm' num2str(fwhm) '.' fsaverage '.nii.gz'];
%         err = save_nifti(surfMASKhdr_rh, fout);
    end
end

