#!/usr/bin/env bash

##########################################################################################################################
## CCS SCRIPT TO DO FINAL PREPROCESSING STEPS OF RESTING_STATE SCAN
##
## R-fMRI master: Xi-Nian Zuo.
## Email: zuoxn@psych.ac.cn or zuoxinian@gmail.com.
##########################################################################################################################

## subject
subject=$1
## analysisdirectory
dir=$2
## resting-state filename (no extension)
rest=$3
## name of anatomical directory
anat_dir_name=$4
## name of func directory
func_dir_name=$5
## if refined anat registration with the study-specific symmetric template: remember to put your study-specific
## template in ${dir}/group/template/template_head.nii.gz
## standard surface
fsaverage=$6
## FreeSurfer SUBJECTS_DIR
SUBJECTS_DIR=$7
## name of registration dir
reg_dir_name=$8

## set your desired spatial smoothing FWHM - we use 6 (acquisition voxel size is 3x3x4mm)
FWHM=6 ; sigma=`echo "scale=10 ; ${FWHM}/2.3548" | bc`

if [ $# -lt 6 ];
then
        echo -e "\033[47;35m Usage: $0 subject analysis_dir rest_name anat_dir_name func_dir_name fsaverage (only name) SUBJECTS_DIR reg_dir_name \033[0m"
        exit
fi

echo --------------------------------------------------------
echo !!!! RUNNING FINAL PREPROCESSING OF FUNCTIONAL DATA !!!!
echo --------------------------------------------------------

if [ $# -lt 7 ];
then
    SUBJECTS_DIR=${dir}
fi

if [ $# -lt 8 ];
then
    reg_dir_name=reg
fi

## directory setup
func_dir=${dir}/${subject}/${func_dir_name}
func_reg_dir=${func_dir}/reg
func_mask_dir=${func_dir}/mask
anat_dir=${dir}/${subject}/${anat_dir_name}
anat_reg_dir=${anat_dir}/${reg_dir_name}
FC_dir=${func_dir}

if [ ! -f ${FC_dir}/${rest}_pp_nofilt_sm0.nii.gz ]
then
        ## 1.Detrending
        echo "Removing linear and quadratic trends for ${subject}"
        if [ ! -f ${FC_dir}/${rest}_res_mean.nii.gz ]
	then
		3dTstat -mean -prefix ${FC_dir}/${rest}_res_mean.nii.gz ${FC_dir}/${rest}_res.nii.gz
	fi
        3dDetrend -polort 2 -prefix ${FC_dir}/tmp_dt.nii.gz ${FC_dir}/${rest}_res.nii.gz
        3dcalc -a ${FC_dir}/${rest}_res_mean.nii.gz -b ${FC_dir}/tmp_dt.nii.gz -expr 'a+b' -prefix ${FC_dir}/${rest}_pp_nofilt_sm0.nii.gz
        rm -rv ${FC_dir}/tmp_dt.nii.gz
        ## 3. Spatial smoothing
        #volume
        mri_fwhm --i ${FC_dir}/${rest}_pp_nofilt_sm0.nii.gz --o ${FC_dir}/${rest}_pp_nofilt_sm${FWHM}.nii.gz --smooth-only --fwhm ${FWHM} --mask ${func_dir}/${rest}_pp_mask.nii.gz
fi
## Surface projection ans smoothing
if [ ! -f ${FC_dir}/${rest}.pp.nofilt.sm${FWHM}.${fsaverage}.rh.nii.gz ]
then
        #surface
        if [ ! -d ${SUBJECTS_DIR}/${fsaverage} ]
        then
                ln -s ${FREESURFER_HOME}/subjects/${fsaverage} ${SUBJECTS_DIR}/${fsaverage}
        fi
	if [ ! -d ${SUBJECTS_DIR}/fsaverage ]
        then
                ln -s ${FREESURFER_HOME}/subjects/fsaverage ${SUBJECTS_DIR}/fsaverage
        fi

        if [ -f ${func_reg_dir}/bbregister.dof6.dat ]
        then
                for hemi in lh rh
                do
                        if [ ! -e ${func_mask_dir}/brain.${fsaverage}.${hemi}.nii.gz ]
			then
				mri_vol2surf --mov ${func_mask_dir}/brain.nii.gz --reg ${func_reg_dir}/bbregister.dof6.dat --trgsubject fsaverage --interp trilin --projfrac 0.5 --hemi ${hemi} --o ${func_mask_dir}/brain.fsaverage.${hemi}.nii.gz --noreshape --cortex --surfreg sphere.reg
                        	mri_surf2surf --srcsubject fsaverage --sval ${func_mask_dir}/brain.fsaverage.${hemi}.nii.gz --hemi ${hemi} --trgsubject ${fsaverage} --tval ${func_mask_dir}/brain.${fsaverage}.${hemi}.nii.gz --surfreg sphere.reg
                        	mri_binarize --i ${func_mask_dir}/brain.fsaverage.${hemi}.nii.gz --min .00001 --o ${func_mask_dir}/brain.fsaverage.${hemi}.nii.gz
                        	mri_binarize --i ${func_mask_dir}/brain.${fsaverage}.${hemi}.nii.gz --min .00001 --o ${func_mask_dir}/brain.${fsaverage}.${hemi}.nii.gz
			fi
			## vol func to fsaverage surface
                        mri_vol2surf --mov ${FC_dir}/${rest}_pp_nofilt_sm0.nii.gz --reg ${func_reg_dir}/bbregister.dof6.dat --trgsubject fsaverage --interp trilin --projfrac 0.5 --hemi ${hemi} --o ${FC_dir}/tmp.${hemi}.nii.gz --noreshape --cortex --surfreg sphere.reg
                        ## smoothing on fsaverage surface
                        mris_fwhm --s fsaverage --hemi ${hemi} --smooth-only --i ${FC_dir}/tmp.${hemi}.nii.gz --fwhm ${FWHM} --o ${FC_dir}/tmp.sm${FWHM}.${hemi}.nii.gz --mask ${func_dir}/mask/brain.fsaverage.${hemi}.nii.gz
                        ## down-sample to ${fsaverage}
                        mri_surf2surf --srcsubject fsaverage --sval ${FC_dir}/tmp.${hemi}.nii.gz  --hemi ${hemi} --cortex --trgsubject ${fsaverage} --tval ${FC_dir}/${rest}.pp.nofilt.sm0.${fsaverage}.${hemi}.nii.gz --surfreg sphere.reg
                        mri_surf2surf --srcsubject fsaverage --sval ${FC_dir}/tmp.sm${FWHM}.${hemi}.nii.gz  --hemi ${hemi} --cortex --trgsubject ${fsaverage} --tval ${FC_dir}/${rest}.pp.nofilt.sm${FWHM}.${fsaverage}.${hemi}.nii.gz --surfreg sphere.reg
                        rm -rv ${FC_dir}/tmp*.nii.gz
                done
        else
                echo "Please first run bbregister for this subject!"
        fi
fi
