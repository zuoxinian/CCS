#!/usr/bin/env bash

##########################################################################################################################
## CCS SCRIPT TO PREPROCESS THE DTI SCAN (INTEGRATE AFNI AND FSL)
##
## R-fMRI master: Xi-Nian Zuo. Aug. 13, 2011.
##
## Last Modified: Dec., 12, 2015.
## Email: zuoxn@psych.ac.cn or zuoxinian@gmail.com.
##########################################################################################################################

## subject
subject=$1
## analysisdirectory
dir=$2
## name of the diffusion imaging scan
dti=$3
## name of the dti directory
dti_dir_name=$4
## name of anatomical directory
anat_dir_name=$5

## directory setup
dti_dir=${dir}/${subject}/${dti_dir_name}
anat_dir=${dir}/${subject}/${anat_dir_name}

if [ $# -lt 5 ];
then
        echo -e "\033[47;35m Usage: $0 subject analysis_dir dti_name dti_dir_name dir_rep anat_dir_name \033[0m "
        exit
fi

echo ---------------------------------------
echo !!!! PREPROCESSING DIFFUSION SCAN !!!!
echo ---------------------------------------

cd ${dti_dir}

## 0. Getting the basic parameters
echo "Getting the basic parameters"
n_vols=`fslnvols ${dti}.nii.gz` ; 
echo "there are ${n_vols} vols"

## 1. Eddy Correction
if [ ! -f data_eddy.nii.gz ]
then
	echo "Eddy correcting ${subject}"
	eddy_correct ${dti}.nii.gz data_eddy.nii.gz 0
fi

## 2. Extract B0 brain and Unique diffusion images
numB0=0; numDiff=0
3drefit -deoblique data_eddy.nii.gz
fslroi data_eddy.nii.gz b0.nii.gz 0 1
for b0ID in `cat ${dti}.bval`
do
    if [ ${numDiff} -eq 0 ]
    then
	b0val=${b0ID}
    fi
    if [ "$b0ID" -eq "$b0ID" ] 2>/dev/null;
    then
        let numDiff=numDiff+1
    fi
done
if [[ ${n_vols} == ${numDiff} ]]
then
    numDiff=0 ; mkdir -p b0_pool
    fslmaths b0.nii.gz -mul 0 b0.nii.gz
    for b0ID in `cat ${dti}.bval`
    do
	if [[ ${b0ID} == ${b0val} ]]
	then
	    let numB0=numB0+1
	    echo "The B0-${numB0} image is detected."
	    fslroi data_eddy.nii.gz b0_pool/b0_${numB0}.nii.gz ${numDiff} 1
	    fslmaths b0.nii.gz -add b0_pool/b0_${numB0}.nii.gz b0.nii.gz
	fi
	let numDiff=numDiff+1
    done
    fslmaths b0.nii.gz -div ${numB0} b0.nii.gz ; rm -rv b0_pool
fi
echo "there are ${numDiff} directions"
bet b0.nii.gz b0_brain.nii.gz -f 0.2 -m
## 3. Refine the B0 brain and mask
echo "Refining the B0 brain and its mask with the T1 image"
mkdir -p ${dti_dir}/reg
flirt -ref ${anat_dir}/reg/highres_rpi.nii.gz -in b0_brain -out ${dti_dir}/reg/b02highres4mask -omat ${dti_dir}/reg/b02highres4mask.mat -cost corratio -dof 6 -interp trilinear #here should use highres_rpi
## 4. Create mat file for conversion from subject's anatomical to diffusion
convert_xfm -inverse -omat ${dti_dir}/reg/highres2b04mask.mat ${dti_dir}/reg/b02highres4mask.mat
flirt -ref b0 -in ${anat_dir}/reg/highres_rpi.nii.gz -out tmpT1.nii.gz -applyxfm -init ${dti_dir}/reg/highres2b04mask.mat -interp trilinear
fslmaths tmpT1.nii.gz -bin -dilM ${dti_dir}/reg/brainmask2b0.nii.gz ; rm -v tmp*.nii.gz
fslmaths b0_brain_mask.nii.gz -mul ${dti_dir}/reg/brainmask2b0.nii.gz b0_brain_mask.nii.gz -odt char
fslmaths b0.nii.gz -mas b0_brain_mask.nii.gz b0_brain.nii.gz

