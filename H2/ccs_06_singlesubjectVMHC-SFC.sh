#!/usr/bin/env bash

##########################################################################################################################
## CCS SCRIPT TO CALCULATE SEED-BASED RESTING-STATE FUNCTIONAL CONNECTIVITY
##
## This script can be run on its own, by filling in the appropriate parameters
##
## Written by Clare Kelly, Maarten Mennes & Michael Milham
## for more information see www.nitrc.org/projects/fcon_1000
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
## file containing list with full/path/to/seed.nii.gz
seed_list=$6
## if remove global signal
globalsignal_removal=$7
## standard template (need a symm template)
standard_template=$8 
## name of reg dir
reg_dir_name=$9

## directory setup see below
SUBJECTS_DIR=${dir}

## parameter setup for preproc

## set your desired spatial smoothing FWHM - we use 6 (acquisition voxel size is 3x3x4mm)
FWHM=6 ; sigma=`echo "scale=10 ; ${FWHM}/2.3548" | bc`

if [ $# -lt 8 ];
then
        echo -e "\033[47;35m Usage: $0 analysis_dir subject_list rest_name anat_dir_name func_dir_name seed_list gs_removal standard_template (symm) \033[0m"
        exit
fi

## Get subjects to run
subjects=$( cat ${subject_list} )
## Get seeds to run
seeds=$( cat ${seed_list} )

if [ $# -lt 9 ];
then
        reg_dir_name=reg
fi

## A. SUBJECT LOOP
for subject in $subjects
do

## directory setup
func_dir=${dir}/${subject}/${func_dir_name}
func_reg_dir=${func_dir}/reg
anat_dir=${dir}/${subject}/${anat_dir_name}
anat_reg_dir=${anat_dir}/${reg_dir_name}
if [ ${globalsignal_removal} = 'true' ]
then
	res_dir=${func_dir}/gs-removal
	RSFC_dir=${func_dir}/RSFC-gs
	vmhc_dir=${func_dir}/VMHC-gs
else
	res_dir=${func_dir}
	RSFC_dir=${func_dir}/RSFC
	vmhc_dir=${func_dir}/VMHC
fi
seed_ts_dir=${RSFC_dir}/seeds

echo --------------------------
echo running subject ${subject}
echo --------------------------

mkdir -p ${seed_ts_dir} ; cd ${RSFC_dir}

## A. SEED_LOOP
for seed in $seeds
do
	seed_name=$( echo ${seed##*/} | sed s/\.nii\.gz//g )
	echo \------------------------
	echo running seed ${seed_name}
	echo \------------------------
	if [ -f ${RSFC_dir}/${seed_name}_Zmap.nii.gz ]; 
	then 
		echo final file for seed ${seed_name} already exists; 
		continue; 
	fi
	nvols=`fslnvols ${res_dir}/${rest}_pp_sm${FWHM}.nii.gz` ; echo "there are ${nvols} vols"
	## 1. Extract Timeseries
        echo Extracting timeseries for seed ${seed_name}
	if [ ! -f ${vmhc_dir}/${rest}_sm${FWHM}_res2symmstandard.nii.gz ]
	then
		echo Applying warp to ${rest}_pp
                applywarp --ref=${standard_template} --in=${res_dir}/${rest}_pp_sm${FWHM}.nii.gz --out=${vmhc_dir}/${rest}_sm${FWHM}_res2symmstandard.nii.gz --warp=${anat_reg_dir}/highres2symmstandard_warp.nii.gz --premat=${func_reg_dir}/example_func2highres.mat
	fi
	3dROIstats -quiet -mask_f2short -mask ${seed} ${vmhc_dir}/${rest}_sm${FWHM}_res2symmstandard.nii.gz > ${seed_ts_dir}/${seed_name}.1D
	## 2. Compute voxel-wise correlation with Seed Timeseries      
        echo Computing Correlation for seed ${seed_name}
        rm -f ${seed_name}_Rmap.nii.gz
        3dfim+ -input ${res_dir}/${rest}_pp_sm${FWHM}.nii.gz -ideal_file ${seed_ts_dir}/${seed_name}.1D -out Correlation -bucket ${seed_name}_Rmap.nii.gz
	## 3. Z-transform correlations		
	echo Z-transforming correlations for seed ${seed_name}
	rm -f ${seed_name}_Zmap.nii.gz
	3dcalc -a ${seed_name}_Rmap.nii.gz -expr 'log((a+1)/(1-a))/2' -prefix ${seed_name}_Zmap.nii.gz
	## 4. Computing Z-statistics
	echo Computing Z-statistical map for seed ${seed_name}
	rm -f ${seed_name}_Zstat.nii.gz
	3dcalc -a ${seed_name}_Zmap.nii.gz -expr 'a*sqrt('${nvols}'-3)' -prefix ${seed_name}_Zstat.nii.gz
	## 5. Registering Z-transformed RSFC maps to standard space
    	echo Registering Z-transformed R to study-specific template
    	applywarp --ref=${standard_template} --in=${seed_name}_Zmap.nii.gz --out=fnirt_${seed_name}_Zmap.nii.gz --warp=${anat_reg_dir}/highres2symmstandard_warp --premat=${func_reg_dir}/example_func2highres.mat
## END OF SEED LOOP
done
## END OF SUBJECT LOOP
done
