#!/usr/bin/env bash

##########################################################################################################################
## CCS SCRIPT TO DO SURFACE-BASED DIFFUSION IMAGE PREPROCESSING (FREESURFER)
##
## !!!!!*****ALWAYS CHECK YOUR REGISTRATIONS*****!!!!!
##
## Written by R-fMRI master: Xi-Nian Zuo. Dec. 07, 2012, Institute of Psychology, CAS.
##
## Email: zuoxn@psych.ac.cn or zuoxinian@gmail.com.
##########################################################################################################################

## subject
subject=$1
## analysisdir
dir=$2
## name of functional directory
dti_dir_name=$4
## name of the resting-state scan
dti_name=$3
## fsaverage
fsaverage=$5
## directory setup
dti_dir=${dir}/${subject}/${dti_dir_name}
dti_reg_dir=${dti_dir}/reg
dti_seg_dir=${dti_dir}/segment
dti_mask_dir=${dti_dir}/mask
SUBJECTS_DIR=${dir}

if [ $# -lt 5 ];
then
        echo -e "\033[47;35m Usage: $0 subject analysis_dir dti_name dti_dir_name fsaverage \033[0m"
        exit
fi

if [ ! -d ${SUBJECTS_DIR}/${fsaverage} ]
then
        ln -s ${FREESURFER_HOME}/subjects/${fsaverage} ${SUBJECTS_DIR}/${fsaverage}
fi

cwd=$( pwd )
if [ -f ${SUBJECTS_DIR}/${subject}/scripts/recon-all.done ]
then
	## 1. Performing bbregister
	if [ ! -e ${dti_reg_dir}/bbregister.dof6.dat ]
	then
		mkdir -p ${dti_reg_dir} ; cd ${dti_reg_dir}
        	bbregister --s ${subject} --mov ${dti_dir}/b0_brain.nii.gz --reg bbregister.dof6.init.dat --init-fsl --dti --fslmat flirt.init.mtx
		bb_init_mincost=`cut -c 1-8 bbregister.dof6.init.dat.mincost`
		comp=`expr ${bb_init_mincost} \> 0.35`
		if [ "$comp" -eq "1" ];
		then
			bbregister --s ${subject} --mov ${dti_dir}/b0_brain.nii.gz --reg bbregister.dof6.dat --init-reg bbregister.dof6.init.dat --dti --fslmat flirt.mtx
			bb_mincost=`cut -c 1-8 bbregister.dof6.dat.mincost`
	                comp=`expr ${bb_mincost} \> 0.35`
			if [ "$comp" -eq "1" ];
                	then
				echo "BBregister seems still problematic, needs a posthoc visual inspection!" >> warnings.bbregister
			fi
		else
			cp bbregister.dof6.init.dat bbregister.dof6.dat
		fi
	fi	
	## 2. Making mask for surface-based functional data analysis
	if [ ! -e ${dti_mask_dir}/brain.mni305.2mm.nii.gz ]; then
		mkdir -p ${dti_mask_dir} ; cd ${dti_mask_dir} ; ln -s ${dti_dir}/b0_brain_mask.nii.gz brain.nii.gz
		for hemi in lh rh
		do
			#surf-mask
			mri_vol2surf --mov brain.nii.gz --reg ${dti_reg_dir}/bbregister.dof6.dat --trgsubject ${fsaverage} --interp nearest --projfrac 0.5 --hemi ${hemi} --o brain.${fsaverage}.${hemi}.nii.gz --noreshape --cortex --surfreg sphere.reg
			mri_binarize --i brain.${fsaverage}.${hemi}.nii.gz --min .00001 --o brain.${fsaverage}.${hemi}.nii.gz
		done
		#volume-mask
        	mri_vol2vol --mov brain.nii.gz --reg ${dti_reg_dir}/bbregister.dof6.dat --tal --talres 2 --talxfm talairach.xfm --nearest --no-save-reg --o brain.mni305.2mm.nii.gz
	fi
	## 3. Coregistering aparc+aseg to native diffusion spcace
        if [ ! -e ${dti_seg_dir}/aparc.a2009s+aseg2diff.nii.gz ]
        then
                mri_vol2vol --mov ${dti_dir}/b0.nii.gz --targ ${SUBJECTS_DIR}/${subject}/mri/aparc.a2009s+aseg.mgz --inv --interp nearest --o ${dti_seg_dir}/aparc.a2009s+aseg2diff.nii.gz --reg ${dti_reg_dir}/bbregister.dof6.dat --no-save-reg
        fi
else
       	echo "Please run recon-all for this subject first!"
fi

## Back to the directory
cd ${cwd}
