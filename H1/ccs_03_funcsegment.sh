#!/usr/bin/env bash

##########################################################################################################################
## CCS SCRIPT TO DO SEGMENTATION OF FUNCTIONAL SCAN
##
## R-fMRI master: Xi-Nian Zuo at the Institute of Psychology, CAS.
## Email: zuoxn@psych.ac.cn
## References:
## [1]. Biswal BB, Mennes M, Zuo XN, et al. Toward discovery science of human brain function. 
##	Proc Natl Acad Sci U S A. 2010 Mar 9;107(10):4734-9.
## [2]. Jo HJ, Saad ZS, Simmons WK, Milbury LA, Cox RW. Mapping sources of correlation in resting state FMRI, 
##	with artifact detection and removal. Neuroimage. 2010 Aug 15;52(2):571-82.
##
## Last Modified: 08/01/2014
## 
##########################################################################################################################

## subject
subject=$1
## analysisdirectory
dir=$2
## filename of resting-state scan (no extension)
rest=$3
## name of anat directory
anat_dir_name=$4
## name of func directory
func_dir_name=$5

## directory setup
anat_dir=${dir}/${subject}/${anat_dir_name}
func_dir=${dir}/${subject}/${func_dir_name}
func_reg_dir=${func_dir}/reg
anat_seg_dir=${anat_dir}/segment
func_seg_dir=${func_dir}/segment

SUBJECTS_DIR=${dir}

if [ $# -lt 5 ];
then
        echo -e "\033[47;35m Usage: $0 subject analysis_dir rest_name anat_dir_name func_dir_name \033[0m"
        exit
fi

echo -----------------------------------------
echo !!!! RUNNING FUNCTIONAL SEGMENTATION !!!!
echo -----------------------------------------


## 1. Make segment dir
mkdir -p ${func_seg_dir}

cwd=$( pwd )
## 2. Change to func dir
cd ${func_seg_dir}

## 3. Copy functional mask from FSLpreproc step 5 - this is the global signal mask
if [ ! -e ${func_seg_dir}/global_mask.nii.gz ]
then 
	3dcopy ${func_dir}/${rest}_pp_mask.nii.gz ${func_seg_dir}/global_mask.nii.gz
fi

## CSF
## 4. Register csf to native space
echo "Registering ${subject} csf to native (functional) space"
#FS
if [ -e ${func_reg_dir}/bbregister.dof6.dat ]
then
	mri_label2vol --seg ${anat_seg_dir}/segment_csf.nii.gz --reg ${func_reg_dir}/bbregister.dof6.dat --temp ${func_dir}/example_func.nii.gz --fillthresh 0.1 --o ${func_seg_dir}/csf2func_fs.nii.gz --pvf ${func_seg_dir}/csf2func_fs_pvf.nii.gz
	fslmaths ${func_seg_dir}/csf2func_fs.nii.gz -mas ${func_seg_dir}/global_mask.nii.gz -bin ${func_dir}/csf_mask_fs.nii.gz
	overlay 1 1 ${func_dir}/example_func.nii.gz -a ${func_dir}/csf_mask_fs.nii.gz 1 1 rendered_mask.nii.gz
	slicer rendered_mask -a csf_mask_fs.png
	title=ccs.qcp.func.segment.csf
	convert -font helvetica -fill white -pointsize 10 -draw "text 10,10 '$title'" csf_mask_fs.png csf_mask_fs.png
fi
rm -f rendered_mask.nii.gz

## WM
## 5. Register wm to native space
#FS
if [ -e ${func_reg_dir}/bbregister.dof6.dat ]
then
	mri_label2vol --seg ${anat_seg_dir}/segment_wm.nii.gz --reg ${func_reg_dir}/bbregister.dof6.dat --temp ${func_dir}/example_func.nii.gz --fillthresh 0.95 --o ${func_seg_dir}/wm2func_fs.nii.gz --pvf ${func_seg_dir}/wm2func_fs_pvf.nii.gz
	fslmaths ${func_seg_dir}/wm2func_fs.nii.gz -mas ${func_seg_dir}/global_mask.nii.gz -bin ${func_dir}/wm_mask_fs.nii.gz
	overlay 1 1 ${func_dir}/example_func.nii.gz -a ${func_dir}/wm_mask_fs.nii.gz 1 1 rendered_mask.nii.gz
	slicer rendered_mask -a wm_mask_fs.png
	title=ccs.qcp.func.segment.wm
	convert -font helvetica -fill white -pointsize 10 -draw "text 10,10 '$title'" wm_mask_fs.png wm_mask_fs.png
fi
rm -f rendered_mask.nii.gz

## a2009s parcellation
if [ -e ${func_seg_dir}/parcels165.nii.gz ]
then
	overlay 1 1 ${func_dir}/example_func.nii.gz -a parcels165.nii.gz 1 165 rendered_parcels165.nii.gz
	slicer rendered_parcels165.nii.gz -l ${FSL_DIR}/etc/luts/renderhot.lut -a parcels165.png
	title=ccs.qcp.func.segment.fs165parcels
        convert -font helvetica -fill white -pointsize 10 -draw "text 10,10 '$title'" parcels165.png parcels165.png
else
	echo Please run ccs_06_singlesubjectRFMRIparcels.m first!
fi

cd ${cwd}
