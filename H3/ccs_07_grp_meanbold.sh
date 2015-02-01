#!/usr/bin/env bash

##########################################################################################################################
## CCS SCRIPT TO generagte (group mean BOLD file.
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
## group name
group=$8
## name of reg dir
reg_dir_dir=$9

if [ $# -lt 8 ];
then
        echo -e "\033[47;35m Usage: $0 analysis_dir subject_list group_dir anat_dir_name func_dir_name standard_template reg_refine groupID \033[0m"
        exit
fi

## Get subjects to run
subjects=$( cat ${subject_list} )

mkdir -p ${grpdir}/templates ; cd ${grpdir}/templates

if [ $# -lt 9 ];
then
        reg_dir_name=reg
fi

## A. SUBJECT LOOP
k=10
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

echo Warpping mean RfMRI data to ${standard_template} space
        
fslmaths ${func_dir}/rest_mc.nii.gz -Tmean tmp.nii.gz
let k=k+1
if [ ${refine_reg} = 'true' ]
then
    applywarp --ref=${standard_template} --in=tmp.nii.gz --out=sub${k}.nii.gz --warp=${anat_reg_dir}/highres2standard_ref_warp.nii.gz --premat=${func_reg_dir}/example_func2highres.mat
else
    applywarp --ref=${standard_template} --in=tmp.nii.gz --out=sub${k}.nii.gz --warp=${anat_reg_dir}/highres2standard_warp.nii.gz --premat=${func_reg_dir}/example_func2highres.mat
fi

done
echo ${k}
fslmerge -t meanBOLD_${group}.nii.gz sub*.nii.gz
fslmaths meanBOLD_${group}.nii.gz -Tmean template_bold_${group}.nii.gz
rm -rv tmp* sub*
