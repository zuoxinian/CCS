#!/usr/bin/env bash

##########################################################################################################################
## CCS SCRIPT TO DO IMAGE REGISTRATION (FLIRT/FNIRT)
##
## !!!!!*****ALWAYS CHECK YOUR REGISTRATIONS*****!!!!!
##
## R-fMRI master: Xi-Nian Zuo. Dec. 07, 2010, Institute of Psychology, CAS.
##
## Email: zuoxn@psych.ac.cn or zuoxinian@gmail.com.
##########################################################################################################################

## subject
subject=$1
## analysisdir
dir=$2
## name of anatomical directory
anat_dir_name=$3
## name of anatomical registration directory
anat_name=$4

if [ $# -lt 4 ];
then
        echo -e "\033[47;35m Usage: $0 subject analysis_dir anat_dir_name anat_name \033[0m"
        exit
fi

echo ---------------------------------------------------------
echo !!!! Preparation for RUNNING ANATOMICAL REGISTRATION !!!!
echo ---------------------------------------------------------

reg_dir=reg
## directory setup
anat_dir=${dir}/${subject}/${anat_dir_name}
anat_reg_dir=${anat_dir}/${reg_dir}
anat_seg_dir=${anat_dir}/segment

mkdir -p ${anat_reg_dir} ; cd ${anat_reg_dir}

## 1. Prepare anatomical images
if [ -f ${anat_reg_dir}/highres_head.nii.gz ]
then
    rm -v ${anat_reg_dir}/highres_head.nii.gz
fi
mv ${anat_dir}/${anat_name}_fs.nii.gz ${anat_reg_dir}/highres_head.nii.gz

fslmaths ${anat_seg_dir}/brainmask.nii.gz -thr 2 ${anat_seg_dir}/brainmask.nii.gz #clean voxels manually edited in freesurfer (assigned value 1)

fslmaths highres_head.nii.gz -mas ${anat_seg_dir}/brainmask.nii.gz highres.nii.gz

cd ${cwd}
