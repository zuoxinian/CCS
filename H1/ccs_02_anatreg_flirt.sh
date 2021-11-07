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

if [ $# -lt 3 ];
then
        echo -e "\033[47;35m Usage: $0 subject analysis_dir anat_dir_name \033[0m"
        exit
fi

echo ---------------------------------------------------------
echo !!!! Preparation for RUNNING ANATOMICAL REGISTRATION !!!!
echo ---------------------------------------------------------

reg_dir=reg
## directory setup
anat_dir=${dir}/${subject}/${anat_dir_name}
anat_reg_dir=${anat_dir}/${reg_dir}

cd ${anat_reg_dir}
## 1. copy standard (We provide two reg pipelines: FSL and Freesurfer, the latter was done in Recon-all automatically)
standard_head=${FSLDIR}/data/standard/MNI152_T1_2mm.nii.gz
standard=${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz
standard_mask=${FSLDIR}/data/standard/MNI152_T1_2mm_brain_mask_dil.nii.gz
## 2. FLIRT T1->STANDARD
fslreorient2std highres.nii.gz highres_rpi.nii.gz
fslreorient2std highres_head.nii.gz highres_head_rpi.nii.gz # not used, just test for future use
flirt -ref ${standard} -in highres_rpi -out highres_rpi2standard -omat highres_rpi2standard.mat -cost corratio -searchcost corratio -dof 12 -interp trilinear
## 3. Create mat file for conversion from standard to high res
fslreorient2std highres.nii.gz > reorient2rpi.mat
convert_xfm -omat highres2standard.mat -concat highres_rpi2standard.mat reorient2rpi.mat
convert_xfm -inverse -omat standard2highres.mat highres2standard.mat

cd ${cwd}
