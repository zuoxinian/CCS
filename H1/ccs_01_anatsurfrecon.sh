#!/usr/bin/env bash

##########################################################################################################################
## CCS SCRIPT TO DO SEGMENTATION OF ANTOMICAL SCAN (FREESURFER)
##
## R-fMRI master: Xi-Nian Zuo at the Institute of Psychology, CAS.
## Email: zuoxn@psych.ac.cn
## References:
## [1]. Biswal BB, Mennes M, Zuo XN, et al. Toward discovery science of human brain function. 
##	Proc Natl Acad Sci U S A. 2010 Mar 9;107(10):4734-9.
## [2]. Jo HJ, Saad ZS, Simmons WK, Milbury LA, Cox RW. Mapping sources of correlation in resting state FMRI, 
##	with artifact detection and removal. Neuroimage. 2010 Aug 15;52(2):571-82.
##########################################################################################################################

## subject
subject=$1
## analysisdirectory
dir=$2
## filename of anatomical scan (no extension)
anat=$3
## name of anat directory
anat_dir_name=$4
## if use GPU
use_gpu=$5

## directory setup
anat_dir=${dir}/${subject}/${anat_dir_name}
anat_seg_dir=${anat_dir}/segment
SUBJECTS_DIR=${dir}

if [ $# -lt 5 ];
then
        echo -e "\033[47;35m Usage: $0 subject analysis_dir anat_name anat_dir_name use_gpu \033[0m"
        exit
fi

echo ------------------------------------------
echo !!!! RUNNING ANATOMICAL SEGMENTATION !!!!
echo ------------------------------------------


## 1. Make segment dir
mkdir -p ${anat_seg_dir}

## 2. Change to anat dir
cwd=$( pwd ) ; cd ${anat_seg_dir}

## if manually edited brainmask
if [[ -e ${SUBJECTS_DIR}/${subject}/mri/brainmask.edit.mgz ]]
then
	cp ${SUBJECTS_DIR}/${subject}/mri/brainmask.mgz ${SUBJECTS_DIR}/${subject}/mri/brainmask.fsinit.mgz
	cp ${SUBJECTS_DIR}/${subject}/mri/brainmask.edit.mgz ${SUBJECTS_DIR}/${subject}/mri/brainmask.mgz
fi

## 3. Segment the brain (Freeserfer segmentation)
mri_convert -it mgz ${SUBJECTS_DIR}/${subject}/mri/brainmask.mgz -ot nii ${anat_seg_dir}/brainmask.nii.gz
mri_convert -it mgz ${SUBJECTS_DIR}/${subject}/mri/T1.mgz -ot nii ${anat_seg_dir}/T1.nii.gz
if [[ ! -e ${SUBJECTS_DIR}/${subject}/mri/aseg.mgz ]]
then
	echo "Segmenting brain for ${subject} (May take more than 24 hours ...)"
	if [ "${use_gpu}" = "true" ] 
	then
		recon-all -s ${subject} -autorecon2 -autorecon3 -use-gpu -no-isrunning
	else
		recon-all -s ${subject} -autorecon2 -autorecon3 -no-isrunning
	fi
fi
#freesurfer version
mri_binarize --i ${SUBJECTS_DIR}/${subject}/mri/aseg.mgz --o segment_wm.nii.gz --match 2 41 7 46 251 252 253 254 255 --erode 1
mri_binarize --i ${SUBJECTS_DIR}/${subject}/mri/aseg.mgz --o segment_csf.nii.gz --match 4 5 43 44 31 63 --erode 1

cd ${cwd}
