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
## func directory name
func_dir_name=$4
## standard source surface
fsaverage=$5
## hcp workbenck directory
HCPWB_DIR=$6
## caret directory
CARET_DIR=$7

if [ $# -lt 7 ];
then
        echo -e "\033[47;35m Usage: $0 subject analysis_dir rest_name anat_dir_name func_dir_name fsaverage (only name) HCPWB_DIR CARET_DIR \033[0m"
        exit
fi

echo --------------------------------------------------------
echo !!!! RUNNING FINAL PREPROCESSING OF FUNCTIONAL DATA !!!!
echo --------------------------------------------------------

## directory setup
func_dir=${dir}/${subject}/${func_dir_name} ; cd ${func_dir}
for hemi in lh rh
do
    for fwhm in 0 6
    do
        ## no global signal removal
	if [ -f ${rest}.pp.nofilt.sm${fwhm}.${fsaverage}.${hemi}.nii.gz ]
	then
	    mri_surf2surf --srcsubject ${fsaverage} --sval ${rest}.pp.nofilt.sm${fwhm}.${fsaverage}.${hemi}.nii.gz --hemi ${hemi} --cortex --trgsubject fsaverage --tval tmp.fsaverage.${hemi}.nii.gz --surfreg sphere.reg
	    ${HCPWB_DIR}/bin_rh_linux64/wb_command -metric-convert -from-nifti tmp.fsaverage.${hemi}.nii.gz ${HCPWB_DIR}/deform_maps/${hemi}.white.surf.gii tmp.fsaverage.${hemi}.gii
	    if [ ${hemi} = "lh" ]
            then
		${CARET_DIR}/bin_linux_intel64/caret_command -deformation-map-apply ${HCPWB_DIR}/deform_maps/fs_L-to-fs_LR_164k.L.deform_map METRIC_AVERAGE_TILE tmp.fsaverage.${hemi}.gii tmp.fsLR.164k.${hemi}.gii
		${CARET_DIR}/bin_linux_intel64/caret_command -deformation-map-apply ${HCPWB_DIR}/deform_maps/fs_LR.164_to_32k.L.deform_map METRIC_AVERAGE_TILE tmp.fsLR.164k.${hemi}.gii ${rest}.pp.nofilt.sm${fwhm}.fsLR.32k.${hemi}.gii
            fi
	    if [ ${hemi} = "rh" ]
            then
                ${CARET_DIR}/bin_linux_intel64/caret_command -deformation-map-apply ${HCPWB_DIR}/deform_maps/fs_R-to-fs_LR_164k.R.deform_map METRIC_AVERAGE_TILE tmp.fsaverage.${hemi}.gii tmp.fsLR.164k.${hemi}.gii
                ${CARET_DIR}/bin_linux_intel64/caret_command -deformation-map-apply ${HCPWB_DIR}/deform_maps/fs_LR.164_to_32k.R.deform_map METRIC_AVERAGE_TILE tmp.fsLR.164k.${hemi}.gii ${rest}.pp.nofilt.sm${fwhm}.fsLR.32k.${hemi}.gii
            fi
	    rm -rv tmp*
	fi
    done
done
