#!/usr/bin/env bash

##########################################################################################################################
## CCS SCRIPT TO DO SEGMENTATION DIFFUSSION SCAN
##
## R-fMRI master: Xi-Nian Zuo at the Institute of Psychology, CAS.
## Email: zuoxn@psych.ac.cn
##
## Last Modified: 12/20/2014
##
##########################################################################################################################

## subject
subject=$1
## analysisdirectory
dir=$2
## name of func directory
dti_dir_name=$3

## directory setup
dti_dir=${dir}/${subject}/${dti_dir_name}
dti_reg_dir=${dti_dir}/reg-fs6
dti_seg_dir=${dti_dir}/segment

SUBJECTS_DIR=${dir}

if [ $# -lt 3 ];
then
        echo -e "\033[47;35m Usage: $0 subject analysis_dir dti_dir_name \033[0m"
        exit
fi

echo -----------------------------------------
echo !!!! RUNNING DIFFUSSION SEGMENTATION !!!!
echo -----------------------------------------


## 1. Make segment dir
mkdir -p ${dti_seg_dir}

## 2. Coregistering aparc+aseg to native diffusion space
if [ ! -e ${dti_seg_dir}/aparc.a2009s+aseg2diff.nii.gz ]
then
	mri_vol2vol --mov ${dti_dir}/b0.nii.gz --targ ${SUBJECTS_DIR}/${subject}/mri/aparc.a2009s+aseg.mgz --inv --interp nearest --o ${dti_seg_dir}/aparc.a2009s+aseg2diff.nii.gz --reg ${dti_reg_dir}/bbregister.dof6.dat --no-save-reg
fi

## 3. Coregistering yeo2011_17networks_split to native diffusion space
if [ ! -e ${dti_seg_dir}/aparc.yeo2011.split114+aseg2diff.nii.gz ]
then
	mri_aparc2aseg --s ${subject} --volmask --annot aparc.yeo2011.split114
	mri_vol2vol --mov ${dti_dir}/b0.nii.gz --targ ${SUBJECTS_DIR}/${subject}/mri/aparc.yeo2011.split114+aseg.mgz --inv --interp nearest --o ${dti_seg_dir}/aparc.yeo2011.split114+aseg2diff.nii.gz --reg ${dti_reg_dir}/bbregister.dof6.dat --no-save-reg
fi

cd ${cwd}
