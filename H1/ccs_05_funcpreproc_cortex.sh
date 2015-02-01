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
dir=$2 ; SUBJECTS_DIR=${dir}
## resting-state filename (no extension)
rest=$3
## name of anatomical directory
anat_dir_name=$4
## name of func directory
func_dir_name=$5
## if refined anat registration with the study-specific symmetric template: remember to put your study-specific
## standard surface
fsaverage=$6
## name of registration dir
reg_dir_name=$7

## set your desired spatial smoothing FWHM - we use 6 (acquisition voxel size is 3x3x4mm)
FWHM=6 ; sigma=`echo "scale=10 ; ${FWHM}/2.3548" | bc`

## Set high pass and low pass cutoffs for temporal filtering
hp=0.01 ; lp=0.1

if [ $# -lt 6 ];
then
        echo -e "\033[47;35m Usage: $0 subject analysis_dir rest_name anat_dir_name func_dir_name fsaverage (only name) \033[0m"
        exit
fi

echo --------------------------------------------------------
echo !!!! RUNNING FINAL PREPROCESSING OF FUNCTIONAL DATA !!!!
echo --------------------------------------------------------

if [ $# -lt 7 ];
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
gsFC_dir=${func_dir}/gs-removal

mkdir -p ${gsFC_dir}

if [ ! -f ${FC_dir}/${rest}_pp_sm0.nii.gz ]
then
	## 1. Temporal filtering
        echo "Band-pass filtering: ${subject}"
        3dFourier -lowpass ${lp} -highpass ${hp} -retrend -prefix ${gsFC_dir}/${rest}_filt.nii.gz ${gsFC_dir}/${rest}_res-gs.nii.gz
        3dFourier -lowpass ${lp} -highpass ${hp} -retrend -prefix ${FC_dir}/${rest}_filt.nii.gz ${FC_dir}/${rest}_res.nii.gz
        ## 2.Detrending
        echo "Removing linear and quadratic trends for ${subject}"
        3dTstat -mean -prefix ${gsFC_dir}/${rest}_filt_mean.nii.gz ${gsFC_dir}/${rest}_filt.nii.gz
        3dDetrend -polort 2 -prefix ${gsFC_dir}/${rest}_dt.nii.gz ${gsFC_dir}/${rest}_filt.nii.gz
        3dcalc -a ${gsFC_dir}/${rest}_filt_mean.nii.gz -b ${gsFC_dir}/${rest}_dt.nii.gz -expr 'a+b' -prefix ${gsFC_dir}/${rest}_pp_sm0.nii.gz
        3dTstat -mean -prefix ${FC_dir}/${rest}_filt_mean.nii.gz ${FC_dir}/${rest}_filt.nii.gz
        3dDetrend -polort 2 -prefix ${FC_dir}/${rest}_dt.nii.gz ${FC_dir}/${rest}_filt.nii.gz
        3dcalc -a ${FC_dir}/${rest}_filt_mean.nii.gz -b ${FC_dir}/${rest}_dt.nii.gz -expr 'a+b' -prefix ${FC_dir}/${rest}_pp_sm0.nii.gz
        rm -rv ${gsFC_dir}/${rest}_filt.nii.gz ${gsFC_dir}/${rest}_filt_mean.nii.gz ${gsFC_dir}/${rest}_dt.nii.gz
        rm -rv ${FC_dir}/${rest}_filt.nii.gz ${FC_dir}/${rest}_filt_mean.nii.gz ${FC_dir}/${rest}_dt.nii.gz
        ## 3. Spatial smoothing
        #volume
        mri_fwhm --i ${gsFC_dir}/${rest}_pp_sm0.nii.gz --o ${gsFC_dir}/${rest}_pp_sm${FWHM}.nii.gz --smooth-only --fwhm ${FWHM} --mask ${func_dir}/${rest}_pp_mask.nii.gz
        mri_fwhm --i ${FC_dir}/${rest}_pp_sm0.nii.gz --o ${FC_dir}/${rest}_pp_sm${FWHM}.nii.gz --smooth-only --fwhm ${FWHM} --mask ${func_dir}/${rest}_pp_mask.nii.gz
fi

if [ ! -f ${FC_dir}/${rest}.pp.sm${FWHM}.${fsaverage}.lh.nii.gz ]
then
        #surface
        SUBJECTS_DIR=${dir}

        if [ ! -d ${SUBJECTS_DIR}/fsaverage ]
        then
                ln -s ${FREESURFER_HOME}/subjects/fsaverage ${SUBJECTS_DIR}/fsaverage
        fi
	
	if [ ! -d ${SUBJECTS_DIR}/${fsaverage} ]
        then
                ln -s ${FREESURFER_HOME}/subjects/${fsaverage} ${SUBJECTS_DIR}/${fsaverage}
        fi

        if [ -f ${func_reg_dir}/bbregister.dof6.dat ]
        then
                for hemi in lh rh
                do
                        if [ ! -e ${func_mask_dir}/brain.${fsaverage}.${hemi}.nii.gz ]
                        then
                                mri_vol2surf --mov ${func_mask_dir}/brain.nii.gz --reg ${func_reg_dir}/bbregister.dof6.dat --trgsubject fsaverage --interp trilin --projfrac 0.5 --hemi ${hemi} --o ${func_mask_dir}/brain.fsaverage.${hemi}.nii.gz --noreshape --cortex --surfreg sphere.reg
                                mri_surf2surf --srcsubject fsaverage --sval ${func_mask_dir}/brain.fsaverage.${hemi}.nii.gz --hemi ${hemi} --cortex --trgsubject ${fsaverage} --tval ${func_mask_dir}/brain.${fsaverage}.${hemi}.nii.gz --surfreg sphere.reg
                                mri_binarize --i ${func_mask_dir}/brain.fsaverage.${hemi}.nii.gz --min .00001 --o ${func_mask_dir}/brain.fsaverage.${hemi}.nii.gz
                                mri_binarize --i ${func_mask_dir}/brain.${fsaverage}.${hemi}.nii.gz --min .00001 --o ${func_mask_dir}/brain.${fsaverage}.${hemi}.nii.gz
                        fi
			## vol func to fsaverage surface
			mri_vol2surf --mov ${gsFC_dir}/${rest}_pp_sm0.nii.gz --reg ${func_reg_dir}/bbregister.dof6.dat --trgsubject fsaverage --interp trilin --projfrac 0.5 --hemi ${hemi} --o ${gsFC_dir}/tmp.${hemi}.nii.gz --noreshape --cortex --surfreg sphere.reg
                        mri_vol2surf --mov ${FC_dir}/${rest}_pp_sm0.nii.gz --reg ${func_reg_dir}/bbregister.dof6.dat --trgsubject fsaverage --interp trilin --projfrac 0.5 --hemi ${hemi} --o ${FC_dir}/tmp.${hemi}.nii.gz --noreshape --cortex --surfreg sphere.reg
                        ## smoothing on fsaverage surface
			mris_fwhm --s fsaverage --hemi ${hemi} --smooth-only --i ${gsFC_dir}/tmp.${hemi}.nii.gz --fwhm ${FWHM} --o ${gsFC_dir}/tmp.sm${FWHM}.${hemi}.nii.gz --mask ${func_dir}/mask/brain.fsaverage.${hemi}.nii.gz
                        mris_fwhm --s fsaverage --hemi ${hemi} --smooth-only --i ${FC_dir}/tmp.${hemi}.nii.gz --fwhm ${FWHM} --o ${FC_dir}/tmp.sm${FWHM}.${hemi}.nii.gz --mask ${func_dir}/mask/brain.fsaverage.${hemi}.nii.gz
                	## down-sample to ${fsaverage}
			mri_surf2surf --srcsubject fsaverage --sval ${gsFC_dir}/tmp.${hemi}.nii.gz  --hemi ${hemi} --cortex --trgsubject ${fsaverage} --tval ${gsFC_dir}/${rest}.pp.sm0.${fsaverage}.${hemi}.nii.gz --surfreg sphere.reg
			mri_surf2surf --srcsubject fsaverage --sval ${gsFC_dir}/tmp.sm${FWHM}.${hemi}.nii.gz  --hemi ${hemi} --cortex --trgsubject ${fsaverage} --tval ${gsFC_dir}/${rest}.pp.sm${FWHM}.${fsaverage}.${hemi}.nii.gz --surfreg sphere.reg
			mri_surf2surf --srcsubject fsaverage --sval ${FC_dir}/tmp.${hemi}.nii.gz  --hemi ${hemi} --cortex --trgsubject ${fsaverage} --tval ${FC_dir}/${rest}.pp.sm0.${fsaverage}.${hemi}.nii.gz --surfreg sphere.reg
                        mri_surf2surf --srcsubject fsaverage --sval ${FC_dir}/tmp.sm${FWHM}.${hemi}.nii.gz  --hemi ${hemi} --cortex --trgsubject ${fsaverage} --tval ${FC_dir}/${rest}.pp.sm${FWHM}.${fsaverage}.${hemi}.nii.gz --surfreg sphere.reg
			rm -rv ${gsFC_dir}/tmp*.nii.gz ${FC_dir}/tmp*.nii.gz
		done
        else
                echo "Please first run bbregister for this subject!"
        fi
fi
