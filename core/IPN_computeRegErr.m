function [regerr, regerr_mdl] = IPN_computeRegErr(fname_indiv, fname_tmpt, fmask)
%% Getting registration quality
% Author: Xi-Nian Zuo (xinian.zuo@nyumc.org)

%% Prepare T1/MASK data
[nii_target dims] = read_avw(fname_tmpt);
nii_mask = read_avw(fmask);
target = reshape(nii_target, prod(dims(1:3)), 1);
mask = reshape(nii_mask, prod(dims(1:3)), 1);
brain = find(mask > 0); 
target_brain = target(brain);
xcenter = (dims(1) + 1) / 2;
mdl = xcenter-5:xcenter+5; % 10 voxels width middle band
nii_target_mdl = nii_target(mdl,:,:);
dims_mdl = size(nii_target_mdl);
target_mdl = reshape(nii_target_mdl,prod(dims_mdl(1:3)),1);
nii_mask_mdl = nii_mask(mdl,:,:);
mask_mdl = reshape(nii_mask_mdl,prod(dims_mdl(1:3)),1);
midline = find(mask_mdl > 0);
target_midline = target_mdl(midline);
%read individual dataset
[nii_epi, dims] = read_avw(fname_indiv);
epi = reshape(nii_epi, prod(dims(1:3)), 1);
epi_brain = epi(brain,:) ; 
nii_epi_mdl = nii_epi(mdl,:,:);
epi_mdl = reshape(nii_epi_mdl,prod(dims_mdl(1:3)),1);
epi_midline = epi_mdl(midline,:) ; 
%Compute spatial correlation
regerr = corr(epi_brain, target_brain);
regerr_mdl = corr(epi_midline, target_midline);
