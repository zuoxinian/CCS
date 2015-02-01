#!/usr/bin/env bash

##########################################################################################################################
## CCS SCRIPT TO REFINE IMAGE REGISTRATION USING GROUP SPECIFIC TEMPLATE
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
## directory of standard template 
standard_template_dir=$4
## name of template 
standard_template_name=$5
## name of reg directory
reg_dir=$6

if [ $# -lt 5 ];
then
        echo -e "\033[47;35m Usage: $0 subject analysis_dir anat_dir_name standard_template_dir standard_template_name reg_dir \033[0m"
        exit
fi

echo --------------------------------
echo !!!! REFINNING REGISTRATION !!!!
echo --------------------------------


## directory setup
if [ $# -lt 6 ];
then
        reg_dir=reg
fi
anat_dir=${dir}/${subject}/${anat_dir_name}
anat_reg_dir=${anat_dir}/${reg_dir}

if [ ! -d ${anat_reg_dir} ]
then
	mkdir -p ${anat_reg_dir} ; cd ${anat_reg_dir}
	cp ${anat_dir}/reg/* ${anat_reg_dir}/
fi

## 1. Copy required images into reg directory
standard_head=${standard_template_dir}/${standard_template_name}.nii.gz
standard=${standard_template_dir}/${standard_template_name}_brain.nii.gz
standard_mask=${FSLDIR}/data/standard/MNI152_T1_2mm_brain_mask_dil.nii.gz

## 2. cd into reg directory
cd ${anat_reg_dir}
## 3. FLIRT T1->STANDARD
flirt -ref ${standard} -in highres_rpi -out highres_rpi2standard_ref -omat highres_rpi2standard_ref.mat -cost corratio -searchcost corratio -dof 12 -interp trilinear
## Create mat file for conversion from standard to high res
convert_xfm -omat highres2standard_ref.mat -concat highres_rpi2standard_ref.mat reorient2rpi.mat
convert_xfm -inverse -omat standard2highres_ref.mat highres2standard_ref.mat
## 4. FNIRT
echo "Performing nolinear registration ..."
fnirt --in=highres_head --aff=highres2standard_ref.mat --cout=highres2standard_ref_warp --iout=fnirt_highres2standard_ref --jout=highres2standard_ref_jac --config=T1_2_MNI152_2mm --ref=${standard_head} --refmask=${standard_mask} --warpres=10,10,10 > warnings.fnirt
if [ -s ${anat_reg_dir}/warnings.fnirt ]
then
	mv fnirt_highres2standard_ref.nii.gz fnirt_highres2standard_ref_wres10.nii.gz
        fnirt --in=highres_head --aff=highres2standard_ref.mat --cout=highres2standard_ref_warp --iout=fnirt_highres2standard_ref --jout=highres2standard_ref_jac --config=T1_2_MNI152_2mm --ref=${standard_head} --refmask=${standard_mask} --warpres=20,20,20
else
        rm -v warnings.fnirt
fi

cd ${cwd}
