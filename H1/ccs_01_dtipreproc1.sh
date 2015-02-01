#!/usr/bin/env bash

##########################################################################################################################
## CCS SCRIPT TO PREPROCESS THE DTI SCAN (INTEGRATE AFNI AND FSL)
##
## R-fMRI master: Xi-Nian Zuo. Aug. 13, 2011.
##
## Last Modified: Dec., 20, 2014.
## Email: zuoxn@psych.ac.cn or zuoxinian@gmail.com.
##########################################################################################################################

## subject
subject=$1
## analysisdirectory
dir=$2
## name of the resting-state scan
dti=$3
## name of the func directory
dti_dir_name=$4
## number of repeated directions
dir_rep=$5
## name of anatomical directory
anat_dir_name=$6

## directory setup
dti_dir=${dir}/${subject}/${dti_dir_name}
anat_dir=${dir}/${subject}/${anat_dir_name}

if [ $# -lt 6 ];
then
        echo -e "\033[47;35m Usage: $0 subject analysis_dir dti_name dti_dir_name dir_rep anat_dir_name \033[0m "
        exit
fi

echo ---------------------------------------
echo !!!! PREPROCESSING DIFFUSION SCAN !!!!
echo ---------------------------------------

cd ${dti_dir}

## 0. Getting the basic parameters
echo "Getting the basic parameters"
n_vols=`fslnvols ${dti}.nii.gz` ; 
echo "there are ${n_vols} vols"
N=$(echo "scale=0; ${n_vols}/${dir_rep}"|bc) ; 
echo "there are ${N} directions"

## 1. Eddy Correction
if [ ! -f data_eddy.nii.gz ]
then
	echo "Eddy correcting ${subject}"
	eddy_correct ${dti}.nii.gz data_eddy.nii.gz 0
fi

## 2. Extract B0 brain and Unique diffusion images
rm -v b0_brain.nii.gz
bet b0.nii.gz b0_brain.nii.gz -f 0.2 -m
## 3. Refine the B0 brain and mask
echo "Refining the B0 brain and its mask with the T1 image"
mkdir -p ${dti_dir}/reg
flirt -ref ${anat_dir}/reg/highres_rpi.nii.gz -in b0_brain -out ${dti_dir}/reg/b02highres4mask -omat ${dti_dir}/reg/b02highres4mask.mat -cost corratio -dof 6 -interp trilinear #here should use highres_rpi
## 4. Create mat file for conversion from subject's anatomical to diffusion
convert_xfm -inverse -omat ${dti_dir}/reg/highres2b04mask.mat ${dti_dir}/reg/b02highres4mask.mat
flirt -ref b0 -in ${anat_dir}/reg/highres_rpi.nii.gz -out tmpT1.nii.gz -applyxfm -init ${dti_dir}/reg/highres2b04mask.mat -interp trilinear
fslmaths tmpT1.nii.gz -bin -dilM ${dti_dir}/reg/brainmask2b0.nii.gz ; rm -v tmp*.nii.gz
fslmaths b0_brain_mask.nii.gz -mul ${dti_dir}/reg/brainmask2b0.nii.gz b0_brain_mask.nii.gz -odt char
fslmaths b0.nii.gz -mas b0_brain_mask.nii.gz b0_brain.nii.gz

