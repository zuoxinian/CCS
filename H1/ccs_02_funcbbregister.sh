#!/usr/bin/env bash

##########################################################################################################################
## CCS SCRIPT TO DO SURFACE-BASED FUNCTIONAL IMAGE PREPROCESSING (FREESURFER)
##
## !!!!!*****ALWAYS CHECK YOUR REGISTRATIONS*****!!!!!
##
## Written by R-fMRI master: Xi-Nian Zuo. Dec. 07, 2010, Institute of Psychology, CAS.
##
## Email: zuoxn@psych.ac.cn or zuoxinian@gmail.com.
##
## Last Modified: 12/13/2015.
##########################################################################################################################

## subject
subject=$1
## analysisdir
dir=$2
## name of functional directory
func_dir_name=$3
## name of the resting-state scan
rest=$4
## name of target average subject
fsaverage=$5
## FreeSurfer SUBJECTS_DIR
SUBJECTS_DIR=$6
## reference image for bbregister (fullpath)
ref_epi=$7
## directory setup
func_dir=${dir}/${subject}/${func_dir_name}
func_reg_dir=${func_dir}/reg
func_seg_dir=${func_dir}/segment
func_mask_dir=${func_dir}/mask

if [ $# -lt 5 ];
then
        echo -e "\033[47;35m Usage: $0 subject analysis_dir func_dir_name rest_name fsaverage ref_epi \033[0m"
        exit
fi

if [ $# -lt 6 ];
then
    SUBJECTS_DIR=${dir}
fi

if [ ! -d ${SUBJECTS_DIR}/fsaverage ]
then
	ln -s ${FREESURFER_HOME}/subjects/fsaverage ${SUBJECTS_DIR}/fsaverage
fi

if [ ! -d ${SUBJECTS_DIR}/${fsaverage} ]
then
        ln -s ${FREESURFER_HOME}/subjects/${fsaverage} ${SUBJECTS_DIR}/${fsaverage}
fi

if [ -f ${SUBJECTS_DIR}/${subject}/scripts/recon-all.done ]
then
	## 1. Performing bbregister
	if [ ! -e ${func_reg_dir}/bbregister.dof6.dat ]
	then
		mkdir -p ${func_reg_dir} ; cd ${func_reg_dir}
		if [ $# -lt 7 ];
		then
		    mov=${func_dir}/example_func_brain.nii.gz
		else
		    flirt -dof 6 -ref ${ref_epi} -in ${func_dir}/example_func_brain.nii.gz -out example_func2ref_brain.nii.gz -omat example_func2ref.mat
		    convert_xfm -omat ref2example_func.mat -inverse example_func2ref.mat
		    flirt -in ${ref_epi} -ref ${func_dir}/example_func_brain.nii.gz -applyxfm -init ref2example_func.mat -out ref2example_func_brain.nii.gz
		    mov=${func_reg_dir}/ref2example_func_brain.nii.gz
		fi
        	bbregister --s ${subject} --mov ${mov} --reg bbregister.dof6.init.dat --init-fsl --bold --fslmat flirt.init.mtx
		bb_init_mincost=`cut -c 1-8 bbregister.dof6.init.dat.mincost`
		comp=`expr ${bb_init_mincost} \> 0.6`
		if [ "$comp" -eq "1" ];
		then
			bbregister --s ${subject} --mov ${mov} --reg bbregister.dof6.dat --init-reg bbregister.dof6.init.dat --bold --fslmat flirt.mtx
			bb_mincost=`cut -c 1-8 bbregister.dof6.dat.mincost`
	                comp=`expr ${bb_mincost} \> 0.6`
			if [ "$comp" -eq "1" ];
                	then
				echo "BBregister seems still problematic, needs a posthoc visual inspection!" >> warnings.bbregister
			fi
		else
			cp ${func_reg_dir}/bbregister.dof6.init.dat ${func_reg_dir}/bbregister.dof6.dat ; 
			cp ${func_reg_dir}/flirt.init.mtx ${func_reg_dir}/flirt.mtx
		fi
	fi	
	## 2. Making mask for surface-based functional data analysis
	if [ ! -e ${func_mask_dir}/brain.mni305.2mm.nii.gz ]; then
		mkdir -p ${func_mask_dir} ; cd ${func_mask_dir} ; cp ${func_dir}/${rest}_pp_mask.nii.gz brain.nii.gz
		for hemi in lh rh
		do
			#surf-mask
			mri_vol2surf --mov brain.nii.gz --reg ${func_reg_dir}/bbregister.dof6.dat --trgsubject fsaverage --interp trilin --projfrac 0.5 --hemi ${hemi} --o brain.fsaverage.${hemi}.nii.gz --noreshape --cortex --surfreg sphere.reg
			mri_surf2surf --srcsubject fsaverage --sval brain.fsaverage.${hemi}.nii.gz --hemi ${hemi} --trgsubject ${fsaverage} --tval brain.${fsaverage}.${hemi}.nii.gz --surfreg sphere.reg
			mri_binarize --i brain.fsaverage.${hemi}.nii.gz --min .00001 --o brain.fsaverage.${hemi}.nii.gz
			mri_binarize --i brain.${fsaverage}.${hemi}.nii.gz --min .00001 --o brain.${fsaverage}.${hemi}.nii.gz
		done
		#volume-mask
        	mri_vol2vol --mov brain.nii.gz --reg ${func_reg_dir}/bbregister.dof6.dat --tal --talres 2 --talxfm talairach.xfm --nearest --no-save-reg --o brain.mni305.2mm.nii.gz
	fi
	## 3. Coregistering aparc+aseg to native functional spcace
	if [ ! -e ${func_seg_dir}/aparc.a2009s+aseg2func.nii.gz ]
	then
		mkdir -p ${func_seg_dir}
		mri_vol2vol --mov ${func_dir}/example_func.nii.gz --targ ${SUBJECTS_DIR}/${subject}/mri/aparc.a2009s+aseg.mgz --inv --interp nearest --o ${func_seg_dir}/aparc.a2009s+aseg2func.nii.gz --reg ${func_reg_dir}/bbregister.dof6.dat --no-save-reg
	fi
else
       	echo "Please run recon-all for this subject first!"
fi

