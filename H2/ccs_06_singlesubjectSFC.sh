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
## if refined anat registration with the study-specific symmetric template: remember to put your study-specific 
## template in ${dir}/group/template/template_head.nii.gz
done_refine_reg=$6
## file containing list with full/path/to/seed.nii.gz
seed_list=$7
## if remove global signal
globalsignal_removal=$8
## standard template
standard_template=$9
# name of reg dir
reg_dir_name=${10}

## directory setup see below
SUBJECTS_DIR=${dir}

## parameter setup for preproc

## set your desired spatial smoothing FWHM - we use 6 (acquisition voxel size is 3x3x4mm)
FWHM=0 ; sigma=`echo "scale=10 ; ${FWHM}/2.3548" | bc`

if [ $# -lt 9 ];
then
        echo -e "\033[47;35m Usage: $0 analysis_dir subject_list rest_name anat_dir_name func_dir_name do_refine_reg seed_list gs_removal standard_template \033[0m"
        exit
fi

if [ $# -lt 10 ];
then
        reg_dir_name=reg
fi

## Get subjects to run
subjects=$( cat ${subject_list} )
## Get seeds to run
seeds=$( cat ${seed_list} )

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
	RSFC_dir=${func_dir}/seedFC-gs
else
	res_dir=${func_dir}
	RSFC_dir=${func_dir}/seedFC
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
	3dROIstats -quiet -mask_f2short -mask ${seed} ${res_dir}/${rest}.sm${FWHM}.mni152.nii.gz > ${seed_ts_dir}/${seed_name}.1D
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
	if [ "${do_refine_reg}" = "true" ];
	then
    		echo Registering Z-transformed R to study-specific template
    		applywarp --ref=${standard_template} --in=${seed_name}_Zmap.nii.gz --out=fnirt_${seed_name}_Zmap.nii.gz --warp=${anat_reg_dir}/highres2standard_ref_warp --premat=${func_reg_dir}/example_func2highres.mat
	else
    		echo Registering Z-transformed R to MNI152 template
    		applywarp --ref=${standard_template} --in=${seed_name}_Zmap.nii.gz --out=fnirt_${seed_name}_Zmap.nii.gz --warp=${anat_reg_dir}/highres2standard_warp --premat=${func_reg_dir}/example_func2highres.mat
	fi
## END OF SEED LOOP
done
## END OF SUBJECT LOOP
done
