#!/usr/bin/env bash

##########################################################################################################################
## CCS SCRIPT TO generagte mask files for second-level group analysis
##
## This script can be run on its own, by filling in the appropriate parameters
## Alternatively this script gets called from batch_process.sh, where you can use it to run N sites, one after the other.
##
## Written by R-fMRI master: Xi-Nian Zuo at IPCAS.
##########################################################################################################################


## analysisdirectory
dir=$1
## full/path/to/subject_list.txt containing subjects you want to run
subject_list=$2
## group analysis directory
grpdir=$3
## name of anatomical directory
anat_dir_name=$4
## name of functional directory
func_dir_name=$5
## standard template which final functional data registered to
standard_template=$6
## if refined anat registration with the study-specific template
refine_reg=$7
## prefix for the mask
prefix=$8
## name of reg dir
reg_dir_name=$9

if [ $# -lt 8 ];
then
        echo -e "\033[47;35m Usage: $0 analysis_dir subject_list group_dir anat_dir_name func_dir_name standard_template reg_refine mask_prefix \033[0m"
        exit
fi

## Get subjects to run
subjects=$( cat ${subject_list} )

mkdir -p ${grpdir}/masks ; cd ${grpdir}/masks
fslmaths ${standard_template} -mul 0 -add 1 mask_${prefix}.nii.gz

if [ $# -lt 9 ];
then
        reg_dir_name=reg
fi

## A. SUBJECT LOOP
for subject in $subjects
do

## directory setup
func_dir=${dir}/${subject}/${func_dir_name}
func_reg_dir=${func_dir}/reg
anat_dir=${dir}/${subject}/${anat_dir_name}
anat_reg_dir=${anat_dir}/${reg_dir_name}

echo -----------------------------
echo processing subject ${subject}
echo -----------------------------

echo Warpping individual mask data to ${standard_template} space

if [ ${refine_reg} = 'true' ]
then
    applywarp --ref=${standard_template} --in=${func_dir}/rest_pp_mask.nii.gz --out=tmp.nii.gz --warp=${anat_reg_dir}/highres2standard_ref_warp.nii.gz --premat=${func_reg_dir}/example_func2highres.mat
else
    applywarp --ref=${standard_template} --in=${func_dir}/rest_pp_mask.nii.gz --out=tmp.nii.gz --warp=${anat_reg_dir}/highres2standard_warp.nii.gz --premat=${func_reg_dir}/example_func2highres.mat
fi

fslmaths tmp.nii.gz -bin tmp_mask.nii.gz
fslmaths mask_${prefix}.nii.gz -mul tmp_mask.nii.gz -bin mask_${prefix}.nii.gz

done

rm -rv tmp*
