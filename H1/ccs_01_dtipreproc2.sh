#!/usr/bin/env bash

##########################################################################################################################
## CCS SCRIPT TO PREPROCESS THE DTI SCAN (INTEGRATE AFNI, FS AND FSL)
##
## R-fMRI master: Xi-Nian Zuo. Dec. 20, 2014.
##
## Last Modified: Dec., 20, 2014.
## Email: zuoxn@psych.ac.cn or zuoxinian@gmail.com.
##########################################################################################################################

## subject
subject=$1
## analysisdirectory
dir=$2
## name of the diffution weighted scan
dti=$3
## name of the dti directory
dti_dir_name=$4
## number of seeds
num_seeds=$5

## directory setup
dti_dir=${dir}/${subject}/${dti_dir_name}
anat_dir=${dir}/${subject}/${anat_dir_name}

if [ $# -lt 5 ];
then
        echo -e "\033[47;35m Usage: $0 subject analysis_dir dti_name dti_dir_name num_seeds \033[0m "
        exit
fi

echo ---------------------------------------
echo !!!! PREPROCESSING DIFFUSION SCAN !!!!
echo ---------------------------------------

echo "Fitting DTI parameters for ${subject}"

#Fitting Diffusion Tensor: FSL-FDT
mkdir -p ${dti_dir}/fdt ; cd ${dti_dir}/fdt
dtifit --data=${dti_dir}/data_eddy.nii.gz --out=dtifit --mask=${dti_dir}/b0_brain_mask.nii.gz --bvecs=${dti_dir}/${dti}.bvec --bvals=${dti_dir}/${dti}.bval

#Fitting Diffusion Tensor: DTK
mkdir -p ${dti_dir}/dtk ; cd ${dti_dir}/dtk
3dTcat -output tmpdata.nii.gz ${dti_dir}/b0.nii.gz ${dti_dir}/data_eddy.nii.gz
cat ${dti_dir}/${dti}.bvec ${dti_dir}/${dti}.bval > tmpgrad.txt
rm -v gradient.txt ; 1dtranspose tmpgrad.txt gradient.txt
echo "0 0 0 0" > gradient.b0
cat gradient.b0 gradient.txt > gradient.gm
dti_recon tmpdata.nii.gz dtifit -gm gradient.gm -b0 1 -it nii.gz -ot nii.gz
rm -v tmp*

#Fitting Diffusion Tensor: FATCAT
mkdir -p ${dti_dir}/fatcat ; cd ${dti_dir}/fatcat
mv ${dti_dir}/${dti}_nob0.bvec ./
mv ${dti_dir}/data_eddy_oneb0.nii.gz ./
3dDWItoDT -prefix dtifit -mask ${dti_dir}/b0_brain_mask.nii.gz -eigs -nonlinear -reweight -sep_dsets ${dti}_nob0.bvec data_eddy_oneb0.nii.gz

#Tracting fibers: DTK
cd ${dti_dir}/dtk
dti_tracker dtifit tracks_${num_seeds}seeds.trk -it nii.gz -at 45 -rseed ${num_seeds} -m ${dti_dir}/b0_brain_mask.nii.gz -m2 dtifit_fa.nii.gz 0.1

