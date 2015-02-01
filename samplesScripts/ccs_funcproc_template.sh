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
scripts_dir=/lfd_app/ccs
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
## standard brain
standard_head=${FSLDIR}/data/standard/MNI152_T1_2mm.nii.gz
standard_brain=${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz
standard_template=${scripts_dir}/templates/MNI152_T1_3mm_brain.nii.gz
fsaverage=fsaverage5


##########################################################################################################################
##---START OF SCRIPT----------------------------------------------------------------------------------------------------##
##########################################################################################################################


## Get subjects to run
subjects=$( cat ${subject_list} )

## SUBJECT LOOP
## Preprocessing functional images
numDropping=5
TR=2.0
sliceOrder=seq+z
#for subject in ${subjects}
#do
	#mkdir -p ${workdir}/${subject}/scripts
	#logfile=${analysisdirectory}/${subject}/scripts/ccs_01_funcpreproc.log
	#if [ ! -f ${logfile} ]
        #then
        	#echo "Running pre-preprocessing functional images for ${subject} ..." > ${logfile}
                #${scripts_dir}/ccs_01_funcpreproc.sh ${subject} ${analysisdirectory} ${rest_name} ${numDropping} ${TR} ${anat_dir_name} ${func_dir_name} ${sliceOrder}
        #fi
#done
        
## Registering functional images
use_epi0=false
anat_reg_refine=false
#for subject in ${subjects}
#do
	#logfile=${analysisdirectory}/${subject}/scripts/ccs_02_funcregister.log
        #if [ ! -f ${logfile} ]
        #then
                #echo "Registering functional images for ${subject} ..." > ${logfile}
		#${scripts_dir}/ccs_02_funcbbregister.sh ${subject} ${analysisdirectory} ${func_dir_name} ${rest_name} ${use_epi0} ${fsaverage}
		#${scripts_dir}/ccs_02_funcregister.sh ${subject} ${analysisdirectory} ${anat_dir_name} ${func_dir_name} ${standard_template} ${anat_reg_refine}
        #fi
#done
#Notice: Please double check the quality of functional registration.
## Quality assurance of the registration
clean_temfiles=true
#${scripts_dir}/ccs_02_funccheck_fnirt.sh ${analysisdirectory} ${subject_list} ${func_dir_name} ${standard_template}
#${scripts_dir}/ccs_02_funccheck_bbregister.sh ${analysisdirectory} ${subject_list} ${func_dir_name} ${clean_tmpfiles} 

## Segmenting functional images
#for subject in ${subjects}
#do
	#logfile=${analysisdirectory}/${subject}/scripts/ccs_03_funcsegment.log
        #if [ ! -f ${logfile} ]
        #then
                #echo "Running segmentation of functional images for ${subject} ..." > ${logfile}
                #${scripts_dir}/ccs_03_funcsegment.sh ${subject} ${analysisdirectory} ${rest_name} ${anat_dir_name} ${func_dir_name}
        #fi
#done

## Nuisance Regression on functional images
#for subject in ${subjects}
#do
        #logfile=${analysisdirectory}/${subject}/scripts/ccs_04_funcnuisance.log
        #if [ ! -f ${logfile} ]
        #then
                #echo "Running nuisance removal of functional images for ${subject} ..." > ${logfile}
        	#${scripts_dir}/ccs_04_funcnuisance.sh ${subject} ${analysisdirectory} ${rest_name} ${func_dir_name} ${svd}
	#fi     
#done

## Final steps of band-pass filtering, detrending and projecting 4D images onto fsaverage surfaces as well as spatial smoothing in both volume and surface spaces
done_refine_anatreg=false
#for subject in ${subjects}
#do
        #logfile=${analysisdirectory}/${subject}/scripts/ccs_05_funcpreproc_final.log
        #if [ ! -f ${logfile} ]
        #then
                #echo "Running final preprocessing steps of functional images for ${subject} ..." > ${logfile}
		#${scripts_dir}/ccs_05_funcpreproc_nofilt.sh ${subject} ${analysisdirectory} ${rest_name} ${anat_dir_name} ${func_dir_name} ${done_refine_anatreg} ${standard_template} ${fsaverage}
        	#${scripts_dir}/ccs_05_funcpreproc.sh ${subject} ${analysisdirectory} ${rest_name} ${anat_dir_name} ${func_dir_name} ${done_refine_anatreg} ${standard_template} ${fsaverage}
	#fi     
#done

## Generate group templates and masks for functional analyses at group level: please run this after the quality control procedure (QCP) done
group_dir=${analysisdirectory}/group
mask_prefix=nyu_trt_subs25
#${scripts_dir}/ccs_07_grp_boldmask.sh ${analysisdirectory} ${subject_list} ${group_dir} ${anat_dir_name} ${func_dir_name} ${standard_template} ${done_refine_anatreg} ${mask_prefix}
#${scripts_dir}/ccs_07_grp_meanbold.sh ${analysisdirectory} ${subject_list} ${group_dir} ${anat_dir_name} ${func_dir_name} ${standard_template} ${done_refine_anatreg} ${mask_prefix}

