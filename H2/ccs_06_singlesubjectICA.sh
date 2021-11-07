#!/usr/bin/env bash

##########################################################################################################################
## CCS SCRIPT TO CALCULATE ICA-BASED RESTING-STATE FUNCTIONAL CONNECTIVITY
##
## This script can be run on its own, by filling in the appropriate parameters
##
## Written by Xi-Nian Zuo. For more information see www.nitrc.org/projects/fcon_1000
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
## if refined anat registration with the study-specific symmetric template: remember to put your study-specific 
## template in ${dir}/group/template/template_head.nii.gz
done_refine_reg=$6
## nuber of components
num_ic=$7
## standard template
standard_template=$8
## standard surface
fsaverage=$9
## name of reg dir
reg_dir_name=${10}

## directory setup see below
SUBJECTS_DIR=${dir}

## parameter setup for preproc

## set your desired spatial smoothing FWHM - we use 6 (acquisition voxel size is 3x3x4mm)
FWHM=6 ; sigma=`echo "scale=10 ; ${FWHM}/2.3548" | bc`

if [ $# -lt 9 ];
then
        echo -e "\033[47;35m Usage: lfcd_06_singlesubjectICA.sh analysis_dir subject_list rest_name anat_dir_name func_dir_name do_refine_reg numIC standard_template fsaverage \033[0m"
        exit
fi

## Get subjects to run
subjects=$( cat ${subject_list} )

if [ $# -lt 10 ];
then
        reg_dir_name=reg
fi

## A. SUBJECT LOOP
for subject in $subjects
do

## directory setup
anat_dir=${dir}/${subject}/${anat_dir_name}
func_dir=${dir}/${subject}/${func_dir_name}
anat_reg_dir=${anat_dir}/${reg_dir_name}
func_reg_dir=${func_dir}/reg
ICA_dir=${func_dir}/ICA

echo --------------------------
echo running subject ${subject}
echo --------------------------

mkdir -p ${ICA_dir} ; cd ${ICA_dir}

# Run ICA
##autoICs
echo "Running MELODIC (${num_ic} components): ${subject}" 
melodic -i ${rest}_pp_sm0.nii.gz --outdir=tmp.ica --mask=${func_dir}/${rest}_pp_mask.nii.gz --nobet --no_mm --Oorig
mkdir -p melodic_autoICs ; mv tmp.ica/melodic_IC.nii.gz melodic_autoICs/melodic_IC.nii.gz ; 
rm -rf tmp.ica
melodic -i ${rest}_pp_sm6.nii.gz --outdir=tmp.ica --mask=${func_dir}/${rest}_pp_mask.nii.gz --nobet --no_mm --Oorig
mkdir -p melodic_autoICs_sm6 ; mv tmp.ica/melodic_IC.nii.gz melodic_autoICs_sm6/melodic_IC.nii.gz ;          
rm -rf tmp.ica
##assigned numICs
echo "Running MELODIC (${num_ic} components): ${subject}"
melodic -i ${rest}_pp_sm0.nii.gz --outdir=tmp.ica --mask=${func_dir}/${rest}_pp_mask.nii.gz --dim=${num_ic} --nobet --no_mm --Oorig
mkdir -p melodic_${num_ic}ICs ; mv tmp.ica/melodic_IC.nii.gz melodic_${num_ic}ICs/melodic_IC.nii.gz ;          
rm -rf tmp.ica
melodic -i ${rest}_pp_sm6.nii.gz --outdir=tmp.ica --mask=${func_dir}/${rest}_pp_mask.nii.gz --dim=${num_ic} --nobet --no_mm --Oorig
mkdir -p melodic_${num_ic}ICs_sm6 ; mv tmp.ica/melodic_IC.nii.gz melodic_${num_ic}ICs_sm6/melodic_IC.nii.gz ;
rm -rf tmp.ica
## Spatial Normalization
if [ "${done_refine_reg}" = "true" ]
then	
	applywarp --ref=${standard_template} --in=melodic_autoICs/melodic_IC.nii.gz --out=melodic_autoICs/fnirt_melodic_IC.nii.gz --warp=${anat_reg_dir}/highres2standard_ref_warp.nii.gz --premat=${func_reg_dir}/example_func2highres.mat
	applywarp --ref=${standard_template} --in=melodic_autoICs_sm6/melodic_IC.nii.gz --out=melodic_autoICs_sm6/fnirt_melodic_IC.nii.gz --warp=${anat_reg_dir}/highres2standard_ref_warp.nii.gz --premat=${func_reg_dir}/example_func2highres.mat
	applywarp --ref=${standard_template} --in=melodic_${num_ic}ICs/melodic_IC.nii.gz --out=melodic_${num_ic}ICs/fnirt_melodic_IC.nii.gz --warp=${anat_reg_dir}/highres2standard_ref_warp.nii.gz --premat=${func_reg_dir}/example_func2highres.mat
	applywarp --ref=${standard_template} --in=melodic_${num_ic}ICs_sm6/melodic_IC.nii.gz --out=melodic_${num_ic}ICs_sm6/fnirt_melodic_IC.nii.gz --warp=${anat_reg_dir}/highres2standard_ref_warp.nii.gz --premat=${func_reg_dir}/example_func2highres.mat
else
	applywarp --ref=${standard_template} --in=melodic_autoICs/melodic_IC.nii.gz --out=melodic_autoICs/fnirt_melodic_IC.nii.gz --warp=${anat_reg_dir}/highres2standard_warp.nii.gz --premat=${func_reg_dir}/example_func2highres.mat
        applywarp --ref=${standard_template} --in=melodic_autoICs_sm6/melodic_IC.nii.gz --out=melodic_autoICs_sm6/fnirt_melodic_IC.nii.gz --warp=${anat_reg_dir}/highres2standard_warp.nii.gz --premat=${func_reg_dir}/example_func2highres.mat
        applywarp --ref=${standard_template} --in=melodic_${num_ic}ICs/melodic_IC.nii.gz --out=melodic_${num_ic}ICs/fnirt_melodic_IC.nii.gz --warp=${anat_reg_dir}/highres2standard_warp.nii.gz --premat=${func_reg_dir}/example_func2highres.mat
        applywarp --ref=${standard_template} --in=melodic_${num_ic}ICs_sm6/melodic_IC.nii.gz --out=melodic_${num_ic}ICs_sm6/fnirt_melodic_IC.nii.gz --warp=${anat_reg_dir}/highres2standard_warp.nii.gz --premat=${func_reg_dir}/example_func2highres.mat
fi
## END OF SUBJECT LOOP
done
