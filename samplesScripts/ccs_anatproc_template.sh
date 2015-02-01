#!/usr/bin/env bash

##########################################################################################################################
## SCRIPT TO RUN GENERAL CCS ANATOMICAL PREPROCESSING
##
## This script can be run on its own, by filling in the appropriate parameters
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
analysisdirectory=/home/xinian/trt # replace by your project directory
## full path to the list of subjects
subject_list=${analysisdirectory}/scripts/subjects.list
## name of anatomical scan (no extension)
anat_name=mprage
## name of resting-state scan (no extension)
rest_name=rest
## anat_dir_name
anat_dir_name=anat
## if do anat registration
do_anat_reg=true 
## if do anat segmentation
do_anat_seg=true
## if use freesurfer derived volumes
fs_brain=true
## if use svd to extract the mean ts
svd=false
## standard brain
standard_head=${FSLDIR}/data/standard/MNI152_T1_2mm.nii.gz
standard_brain=${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz
standard_template=${scripts_dir}/templates/MNI152_T1_3mm_brain.nii.gz
fsaverage=fsaverage5
##########################################################################################################################


##########################################################################################################################
##---START OF SCRIPT----------------------------------------------------------------------------------------------------##
##########################################################################################################################


## Get subjects to run
subjects=$( cat ${subject_list} )

## SUBJECT LOOP

## Preprocessing anatomical images
sanlm_denoise=false
use_gcut=true
num_scans=1
#for subject in ${subjects}
#do
#	mkdir -p ${analysisdirectory}/${subject}/scripts
#	logfile=${analysisdirectory}/${subject}/scripts/ccs_01_anatpreproc.log
#	if [ ! -f ${logfile} ]
#	then 
#		echo "Preprocessing of anatomical images for ${subject} ..." > ${logfile}
#		${scripts_dir}/ccs_01_anatpreproc.sh ${subject} ${analysisdirectory} ${anat_name} ${anat_dir_name} ${sanlm_denoise} ${num_scans} ${use_gcut}
#	fi
#done
## Notice: please check the quality of brain extraction before going to next step !!! (sometime manual edits of the brainmask.mgz are required)

## Segmenting and reconstructing surfaces: anatomical images
use_gpu=false
#for subject in ${subjects}
#do
#	logfile=${analysisdirectory}/${subject}/scripts/ccs_01_anatsurfrecon.log
#	if [ ! -f ${logfile} ]
#       then
#               echo "Segmenting and reconstructing cortical surfaces for ${subject} ..." > ${logfile}
# 		${scripts_dir}/ccs_01_anatsurfrecon.sh ${subject} ${analysisdirectory} ${anat_name} ${anat_dir_name} ${fs_brain} ${use_gpu}
#	fi
#done
## Quaility assurance of surface reconstruction
clean_tmpfiles=true
#${scripts_dir}/ccs_01_anatcheck_surf.sh ${analysisdirectory} ${subject_list} ${anat_dir_name} ${clean_tmpfiles} 

## Registering anatomical images
#for subject in ${subjects}
#do
#       logfile=${analysisdirectory}/${subject}/scripts/ccs_02_anatregister.log
#       if [ ! -f ${logfile} ]
#       then
#               echo "Registering anatomical images to MNI152 template for ${subject} ..." > ${logfile}
#		${scripts_dir}/ccs_02_anatregister.sh ${subject} ${analysisdirectory} ${anat_dir_name}
#	fi	
#done
## Quality assurances of spatial normalization
reg_refine=false
#${scripts_dir}/ccs_02_anatcheck_fnirt.sh ${analysisdirectory} ${subject_list} ${anat_dir_name} ${standard_brain} ${reg_refine}

## Generating group anatomical templates of this set of subjects
template_dir=${analysisdirectory}/group/templates
template_name=nyutrt_subs25
spr=2mm
#${scripts_dir}/ccs_07_grp_meanstruc.sh ${analysisdirectory} ${subject_list} ${anat_dir_name} ${template_dir} ${template_name} ${spr}

