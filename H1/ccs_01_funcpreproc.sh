#!/usr/bin/env bash

##########################################################################################################################
## CCS SCRIPT TO PREPROCESS THE FUNCTIONAL SCAN (INTEGRATE AFNI AND FSL)
##
## R-fMRI master: Xi-Nian Zuo. Aug. 13, 2011; Revised at IPCAS, Feb. 12, 2013.
##
## Email: zuoxn@psych.ac.cn or zuoxinian@gmail.com.
##########################################################################################################################

## subject
subject=$1
## analysisdirectory
dir=$2
## name of the resting-state scan
rest=$3
## number of volumes dropped
ndvols=$4
## TR
TR=$5
## name of the anat directory
anat_dir_name=$6
## name of the func directory
func_dir_name=$7
## Tpattern: see helps from AFNI command 3dTshift, e.g., seq+z or alt+z.
tpattern=$8

## directory setup
func_dir=${dir}/${subject}/${func_dir_name}
anat_dir=${dir}/${subject}/${anat_dir_name}

if [ $# -lt 8 ];
then
        echo -e "\033[47;35m Usage: $0 subject analysis_dir rest_name num_droppingTR TR anat_dir_name func_dir_name tpattern \033[0m"
        exit
fi

echo ---------------------------------------
echo !!!! PREPROCESSING FUNCTIONAL SCAN !!!!
echo ---------------------------------------

cwd=$( pwd )
cd ${func_dir}

## 0. Dropping first # TRS
echo "Dropping first ${ndvols} TRs"
nvols=`fslnvols ${rest}.nii.gz`
## first timepoint (remember timepoint numbering starts from 0)
TRstart=${ndvols} 
## last timepoint
let "TRend = ${nvols} - 1"
if [[ ! -f ${rest}_dr.nii.gz ]]
then
	3dcalc -a ${rest}.nii.gz[${TRstart}..${TRend}] -expr 'a' -prefix ${rest}_dr.nii.gz -datum float
	3drefit -TR ${TR} ${rest}_dr.nii.gz
fi

## 1. Despiking (particular helpful for motion)
echo "Despiking timeseries for ${subject}"
if [[ ! -f ${rest}_dspk.nii.gz ]]
then    
	3dDespike -prefix ${rest}_dspk.nii.gz ${rest}_dr.nii.gz
fi

## 2. Slice timing
echo "Slice timing for ${subject}"
if [[ ! -f ${rest}_ts.nii.gz ]]
then
	3dTshift -prefix ${rest}_ts.nii.gz -tpattern ${tpattern} -tzero 0 ${rest}_dspk.nii.gz
	echo "Deobliquing ${subject}"
	3drefit -deoblique ${rest}_ts.nii.gz
fi

##3. Reorient into fsl friendly space (what AFNI calls RPI)
echo "Reorienting ${subject}"
if [[ ! -f ${rest}_ro.nii.gz ]]
then
	3dresample -orient RPI -inset ${rest}_ts.nii.gz -prefix ${rest}_ro.nii.gz
fi

##4. Motion correct to average of timeseries
echo "Motion correcting ${subject}"
if [[ ! -f ${rest}_ro_mean.nii.gz ]]
then
	3dTstat -mean -prefix ${rest}_ro_mean.nii.gz ${rest}_ro.nii.gz 
fi
3dvolreg -Fourier -twopass -base ${rest}_ro_mean.nii.gz -zpad 4 -prefix ${rest}_mc.nii.gz -1Dfile ${rest}_mc.1D ${rest}_ro.nii.gz

##5. Remove skull/edge detection
echo "Skull stripping ${subject}"
if [[ ! -f ${rest}_mask.nii.gz ]]
then
	3dAutomask -prefix ${rest}_mask.nii.gz -dilate 1 ${rest}_mc.nii.gz
fi

if [[ ! -f ${rest}_ss.nii.gz ]]
then
	fslroi ${rest}_mc.nii.gz example_func.nii.gz 7 1
	fslmaths example_func.nii.gz -mas ${rest}_mask.nii.gz tmpbrain.nii.gz
	mkdir -p ${func_dir}/reg
	flirt -ref ${anat_dir}/reg/highres.nii.gz -in tmpbrain -out ${func_dir}/reg/example_func2highres4mask -omat ${func_dir}/reg/example_func2highres4mask.mat -cost corratio -dof 6 -interp trilinear #here should use highres_rpi
	## Create mat file for conversion from subject's anatomical to functional
	convert_xfm -inverse -omat ${func_dir}/reg/highres2example_func4mask.mat ${func_dir}/reg/example_func2highres4mask.mat
	flirt -ref example_func -in ${anat_dir}/reg/highres.nii.gz -out tmpT1.nii.gz -applyxfm -init ${func_dir}/reg/highres2example_func4mask.mat -interp trilinear
	fslmaths tmpT1.nii.gz -bin -dilM ${func_dir}/reg/brainmask2example_func.nii.gz ; rm -v tmp*.nii.gz
	fslmaths ${rest}_mc.nii.gz -Tstd -bin ${rest}_pp_mask.nii.gz #Rationale: any voxels with detectable signals should be included as in the global mask
	fslmaths ${rest}_pp_mask.nii.gz -mul ${rest}_mask.nii.gz -mul ${func_dir}/reg/brainmask2example_func.nii.gz ${rest}_pp_mask.nii.gz -odt char
	fslmaths example_func.nii.gz -mas ${rest}_pp_mask.nii.gz example_func_brain.nii.gz
	3dcalc -a ${rest}_mc.nii.gz -b ${rest}_pp_mask.nii.gz -expr 'a*b' -prefix ${rest}_ss.nii.gz
fi

##6. Grandmean scaling
echo "Grand-mean scaling ${subject}"
if [[ ! -f ${rest}_gms.nii.gz ]]
then
	fslmaths ${rest}_ss.nii.gz -ing 10000 ${rest}_gms.nii.gz
fi

cd ${cwd}
