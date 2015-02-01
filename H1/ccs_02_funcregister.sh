#!/usr/bin/env bash

##########################################################################################################################
## CCS SCRIPT TO DO IMAGE REGISTRATION (FLIRT/FNIRT)
##
## !!!!!*****ALWAYS CHECK YOUR REGISTRATIONS*****!!!!!
##
## R-fMRI master: Xi-Nian Zuo. Dec. 07, 2010, Institute of Psychology, CAS.
##
## Email: zuoxn@psych.ac.cn or zuoxinian@gmail.com.
##
## Last Modified: 08/01/2014
##
## Note: this will be updated to use ANS or CVS in next CCS version. 
##########################################################################################################################

## subject
subject=$1
## analysisdir
dir=$2
## name of anatomical directory
anat_dir_name=$3
## name of functional directory
func_dir_name=$4
## standard template which final functional data registered to
standard_template=$5
## if refine anat register using group-specific template
anat_reg_refine=$6
## name of reg directory
reg_dir_name=$7

if [ $# -lt 6 ];
then
        echo -e "\033[47;35m Usage: $0 subject analysis_dir anat_dir_name func_dir_name standard_template anat_reg_refine reg_dir_name \033[0m"
        exit
fi

echo ------------------------------------------
echo !!!! RUNNING FUNCTIONAL REGISTRATION !!!!
echo ------------------------------------------


if [ $# -lt 7 ];
then
	reg_dir_name=reg
fi

## directory setup
anat_dir=${dir}/${subject}/${anat_dir_name}
func_dir=${dir}/${subject}/${func_dir_name}
anat_reg_dir=${anat_dir}/${reg_dir_name}
func_reg_dir=${func_dir}/reg

mkdir -p ${func_reg_dir}

if [ -f ${anat_reg_dir}/highres2standard.mat ]
then
	
	## 1. Copy required images into reg directory
	### copy anatomical
	highres=${anat_dir}/segment/highres.nii.gz
	### copy standard
	standard_head=${FSLDIR}/data/standard/MNI152_T1_2mm.nii.gz
	standard=${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz
	### copy example func created earlier
	example_func=${func_dir}/example_func_brain.nii.gz

	## 2. cd into reg directory
	cd ${func_reg_dir}

	## 3. FUNC->T1 using bbregister derived matrix
	echo $subject
	cp flirt.mtx example_func2highres.mat
	## Create mat file for conversion from subject's anatomical to functional
	convert_xfm -inverse -omat highres2example_func.mat example_func2highres.mat

	## 4. FUNC->STANDARD
  	if [ "${anat_reg_refine}" = "true" ];
  	then
		## Create mat file for registration of functional to standard
		convert_xfm -omat example_func2standard.mat -concat ${anat_reg_dir}/highres2standard_ref.mat example_func2highres.mat
		## apply registration
		flirt -ref ${standard} -in ${example_func} -out example_func2standard -applyxfm -init example_func2standard.mat -interp trilinear
		## Create inverse mat file for registration of standard to functional
		convert_xfm -inverse -omat standard2example_func.mat example_func2standard.mat
		## 5. Applying fnirt
		applywarp --ref=${standard_template} --in=${example_func} --out=fnirt_example_func2standard --warp=${anat_reg_dir}/highres2standard_ref_warp --premat=example_func2highres.mat
  	else
		## Create mat file for registration of functional to standard
        	convert_xfm -omat example_func2standard.mat -concat ${anat_reg_dir}/highres2standard.mat example_func2highres.mat
        	## apply registration
        	flirt -ref ${standard} -in ${example_func} -out example_func2standard -applyxfm -init example_func2standard.mat -interp trilinear
        	## Create inverse mat file for registration of standard to functional
        	convert_xfm -inverse -omat standard2example_func.mat example_func2standard.mat
        	## 5. Applying fnirt
       		applywarp --ref=${standard_template} --in=${example_func} --out=fnirt_example_func2standard --warp=${anat_reg_dir}/highres2standard_warp --premat=example_func2highres.mat
  	fi
else
	echo "Please first run registration on anatomical data!"
fi
###***** ALWAYS CHECK YOUR REGISTRATIONS!!! YOU WILL EXPERIENCE PROBLEMS IF YOUR INPUT FILES ARE NOT ORIENTED CORRECTLY (IE. RPI, ACCORDING TO AFNI) *****###

cd ${cwd}
