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
## name of dti directory
dti_dir_name=$3

## directory setup
dti_dir=${dir}/${subject}/${dti_dir_name}
dti_reg_dir=${dti_dir}/reg
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
mkdir -p ${dti_seg_dir} ; cd ${dti_seg_dir}

## a2009s parcellation
if [ -e ${dti_seg_dir}/parcels165.nii.gz ]
then
	overlay 1 1 ${dti_dir}/b0.nii.gz -a parcels165.nii.gz 1 165 rendered_parcels165.nii.gz
	slicer rendered_parcels165.nii.gz -l ${FSL_DIR}/etc/luts/renderjet.lut -a parcels165.png
	title=${subject}.ccs.qcp.dti.segment.165parcels
        convert -font helvetica -fill white -pointsize 10 -draw "text 10,10 '$title'" parcels165.png parcels165.png
else
	echo Please run ccs_06_singlesubjectDMRIparcels.m first!
fi

## yeo2011 parcellation
if [ -e ${dti_seg_dir}/parcels131.nii.gz ]
then
        overlay 1 1 ${dti_dir}/b0.nii.gz -a parcels131.nii.gz 1 131 rendered_parcels131.nii.gz
        slicer rendered_parcels131.nii.gz -l ${FSL_DIR}/etc/luts/renderhsv.lut -a parcels131.png
        title=${subject}.ccs.qcp.dti.segment.131parcels
        convert -font helvetica -fill white -pointsize 10 -draw "text 10,10 '$title'" parcels131.png parcels131.png
else
        echo Please run ccs_06_singlesubjectDMRIparcels.m first!
fi

cd ${cwd}
