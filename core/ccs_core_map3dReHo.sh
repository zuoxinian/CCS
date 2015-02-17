#!/usr/bin/env bash

#################################################################################################
## CCS SCRIPT TO PERFORM REHO COMPUTATION IN 3D VOLUME SPACE (INTEGRATE AFNI AND FSL)
##
## R-fMRI master: Xi-Nian Zuo. Feb. 18, 2015. at Institute of Psychology, CAS.
##
## Email: zuoxn@psych.ac.cn or zuoxinian@gmail.com.
#################################################################################################

## individual preprocessed rfMRI data (isotropic voxel/no spatial smoothing)
rest_pp_sm0=$1
## box size of neighbor voxels (e.g., the box size of containing 9 voxels is 3)
box_size=$2
## name of output ReHo file
reho_name=$3

if [ $# -lt 3 ];
then
        echo -e "\033[47;35m Usage: $0 rest_pp_sm0 box_size reho_name \033[0m"
        exit
fi

if [ ! -f rank.nii.gz ]
then
	echo "Computing temporal ranks: Rank Order Filtering ..."
	3dTsort -overwrite -prefix rank.nii.gz -rank rest_pp_sm0.nii.gz
fi
if [ ! -f mean_rank.nii.gz ]
then
        echo "Computing spatial mean ranks: Mean Filtering ..."
        fslmaths rank.nii.gz -kernel boxv ${box_size} -fmean mean_rank.nii.gz
        NT=`fslnvols rank.nii.gz` ; echo "There are ${NT} volumes ..."
        echo "Computing two primary constants ..."
        NC1=$(echo "scale=20; ${NT}*${NT}*${NT}-${NT}"|bc); echo ${NC1}
        NC2=$(echo "scale=20; 3*(${NT}+1)/(${NT}-1)"|bc); echo ${NC2}
        echo "Computing KCC as ReHo ..."
        fslmaths mean_rank.nii.gz -sqr -Tmean -mul ${NT} -mul 12 -div ${NC1} -sub ${NC2} ${reho_name}.nii.gz
fi

