#!/usr/bin/env bash

##########################################################################################################################
## SCRIPT TO RUN GENERAL RESTING-STATE PREPROCESSING
##
## Written by the R-fMRI master: Xi-Nian Zuo.
## Email: zuoxn@psych.ac.cn.
## 
##########################################################################################################################

##########################################################################################################################
## PARAMETERS
###########################################################################################################################

## directory where scripts are located
scripts_dir=/lfcd_app/ccs
## full/path/to/site
analysisdirectory=/home/xinian/projects/trt
## full/path/to/site/subject_list
subject_list=${analysisdirectory}/scripts/subjects.list
## name of anatomical scan (no extension)
anat_name=mprage
## name of resting-state scan (no extension)
rest_name=rest
## anat_dir_name
anat_dir_name=anat
## func_dir_name
func_dir_name=func
## TR
TR=3.0
## if do anat registration
do_anat_reg=true 
## if do anat segmentation
do_anat_seg=true
## if use freesurfer derived volumes
fs_brain=true
## if use svd to extract the mean ts
svd=false
## if remove global signal
gs_removal=true;
## standard brain
standard_head=${FSLDIR}/data/standard/MNI152_T1_2mm.nii.gz
standard_brain=${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz
standard_template=${scripts_dir}/templates/MNI152_T1_3mm_brain.nii.gz
fsaverage=fsaverage5 # ico=5 in surface making: around 4mm vertex-spacing. 
##########################################################################################################################


##########################################################################################################################
##---START OF SCRIPT----------------------------------------------------------------------------------------------------##
##########################################################################################################################

## ALFF
do_refine_reg=false
#${scripts_dir}/ccs_06_singlesubjectALFF.sh ${analysisdirectory} ${subject_list} ${rest_name} ${TR} ${anat_dir_name} ${func_dir_name} ${do_refine_reg} ${standard_template} ${fsaverage}

## ICA
numIC=20
#${scripts_dir}/ccs_06_singlesubjectICA.sh ${analysisdirectory} ${subject_list} ${rest_name} ${anat_dir_name} ${func_dir_name} ${do_refine_reg} ${numIC} ${standard_template} ${fsaverage}

## ReHo
#${scripts_dir}/ccs_06_singlesubjectReHo.sh ${analysisdirectory} ${subject_list} ${rest_name} ${anat_dir_name} ${func_dir_name} ${do_refine_reg} ${standard_template} ${fsaverage}

## RSFC
seed_list=${scripts_dir}/samples_script/dmn.list
#${scripts_dir}/ccs_06_singlesubjectSFC.sh ${analysisdirectory} ${subject_list} ${rest_name} ${anat_dir_name} ${func_dir_name} ${do_refine_reg} ${seed_list} ${gs_removal} ${standard_template} ${fsaverage}

## VMHC
use_spec_template=false
#${scripts_dir}/ccs_06_singlesubjectVMHC.sh ${analysisdirectory} ${subject_list} ${rest_name} ${anat_dir_name} ${func_dir_name} ${use_spec_template} ${template_name} ${fs_brain} ${gs_removal} ${scripts_dir}
seed_vmhc_list=${scripts_dir}/samples_script/vmhc.list
#${scripts_dir}/ccs_06_singlesubjectVMHC.sh ${analysisdirectory} ${subject_list} ${rest_name} ${anat_dir_name} ${func_dir_name} ${seed_vmhc_list} ${gs_removal} ${standard_template}

