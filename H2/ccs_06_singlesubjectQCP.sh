#!/usr/bin/env bash

##########################################################################################################################
## CCS SCRIPT TO CALCULATE VARIOUS QCP METRICS
##
## This script can be run on its own, by filling in the appropriate parameters
##
## Written by Xi-Nian Zuo. For more information see www.nitrc.org/projects/fcon_1000
##
## See http://preprocessed-connectomes-project.org/quality-assessment-protocol/index.html
##
## Modified by R-fMRI master: Xi-Nian Zuo at IPCAS.
##########################################################################################################################

## analysisdirectory
dir=$1
## full/path/to/subject_list.txt containing subjects you want to run
subject_list=$2
## name of resting-state scan (no extenstion)
rest=$3
## name of anatomical directory
anat_dir_name=$4
## name of functional directory
func_dir_name=$5
## ccs directory (full path)
ccs_dir=$6

## directory setup see below
SUBJECTS_DIR=${dir}

if [ $# -lt 6 ];
then
        echo -e "\033[47;35m Usage: $0 analysis_dir subject_list rest_name anat_dir_name func_dir_name ccs_dir (full path) \033[0m"
        exit
fi

## Get subjects to run
subjects=$( cat ${subject_list} )

## A. SUBJECT LOOP
for subject in $subjects
do

## directory setup
anat_dir=${dir}/${subject}/${anat_dir_name}
func_dir=${dir}/${subject}/${func_dir_name}
func_reg_dir=${func_dir}/reg

echo --------------------------
echo running subject ${subject}
echo --------------------------

# Run FWHM estimation on structural MRI images
cd ${anat_dir} ; mkdir -p qcp
if [ ! -f qcp/FWHM.dat ]
then
    3dFWHMx -input reg/highres_head.nii.gz -mask reg/highres.nii.gz -out qcp/FWHM.dat
fi

# Run QCP metric estimation on rfMRI images
if [ -d ${func_dir} ]
then
    cd ${func_dir} ; mkdir -p qcp
    # Run FWHM estimation on functional MRI images
    3dFWHMx -input ${rest}.nii.gz -mask ${rest}_pp_mask.nii.gz -arith -out qcp/sFWHM.dat
    3dFWHMx -input ${rest}.nii.gz -mask ${rest}_pp_mask.nii.gz -arith -detrend -out qcp/tFWHM.dat

    # Run Standardized DVARS estimation on functional MRI images
    cd qcp ; cp ${ccs_dir}/misc/DVARS.sh ./
    bash DVARS.sh -all ${func_dir}/${rest}_pp_sm6.nii.gz DVARS.dat

    # Run estimation on the Mean Fraction of Outliers for functional MRI images
    3dToutcount -mask ${func_dir}/${rest}_pp_mask.nii.gz -fraction ${func_dir}/${rest}_ro.nii.gz > outliers.dat

    # Run estimation on Median Distance Index for functional MRI images
    3dTqual -mask ${func_dir}/${rest}_pp_mask.nii.gz ${func_dir}/${rest}_ro.nii.gz > MDI.dat
fi
## END OF SUBJECT LOOP
done
