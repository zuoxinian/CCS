#!/usr/bin/env bash

##########################################################################################################################
## CCS SCRIPT TO CALCULATE VOXEL-MIRRORED HOMOTOPIC CONNECTIVITY (ON BOTH VOLUME AND SURFACE) 
##
## This script can be run on its own, by filling in the appropriate parameters
##
## Written by Xi-Nian Zuo, Maarten Mennes & Michael Milham
## for more information see www.nitrc.org/projects/fcon_1000
##
## Updated by R-fMRI master: Xi-Nian Zuo at IPCAS. Need substentially revise to provide surface-based VMHC!!
##########################################################################################################################

## analysisdirectory
dir=$1
## full/path/to/subject_list.txt containing subjects you want to run, you can also specify one subject
subject_list=$2
## name of resting-state scan (no extenstion)
rest=$3
## name of anatomical directory
anat_dir_name=$4
## name of functional directory
func_dir_name=$5
## if refined anat registration with the study-specific symmetric template: remember to put your study-specific 
## template in ${dir}/group/templates/${template_name}.nii.gz
use_spec_template=$6
## template name
template_name=$7
## if remove global signal
global_signal_removal=$8
## full path of LFCD scripts directory
ccs_dir=$9
## name of reg dir
reg_dir_name=${10}

if [ $# -lt 9 ];
then
        echo -e "\033[47;35m Usage: $0 analysis_dir subject_list rest_name anat_dir_name func_dir_name use_spec_template template_name global_signal_removal lfcd_dir \033[0m"
        exit
fi

## Setting up
if [ ${use_spec_template} = 'true' ] 
then
    cd ${dir}/group/templates
    if [ ! -e ${dir}/group/templates/${template_name}.nii.gz ];
    then
	echo Please check if the template exist or do not use study-speccific template.
	exit
    fi
    symm_standard=${dir}/group/templates/${template_name}_symmetric.nii.gz
    symm_standard_brain=${dir}/group/templates/${template_name}_brain_symmetric.nii.gz
    symm_standard_mask=${dir}/group/masks/${template_name}_brain_mask_symmetric_dil.nii.gz ##anatomical
    hemi_standard_mask=${dir}/group/masks/func_${template_name}_hemibrain_mask_nomdl.nii.gz ##functional: use MATLAB to create it!
else
    ## standard brain as reference for registration
    symm_standard=${ccs_dir}/templates/MNI152_T1_2mm_symmetric.nii.gz
    symm_standard_brain=${ccs_dir}/templates/MNI152_T1_2mm_brain_symmetric.nii.gz  
    symm_standard_mask=${ccs_dir}/templates/MNI152_T1_2mm_brain_mask_symmetric_dil.nii.gz
    hemi_standard_mask=${ccs_dir}/templates/MNI152_T1_2mm_hemibrain_mask_nomdl.nii.gz
fi
echo ---------------------------------------
echo !!!! CALCULATING VMHC !!!!
echo ---------------------------------------

if [ $# -lt 10 ];
then
        reg_dir_name=reg
fi

## Get subjects to run
if [ -f ${subject_list} ]
then
    subjects=$( cat ${subject_list} )
else
    subjects=${subject_list}
fi

fwhm=0;

## A. SUBJECT LOOP
for subject in $subjects
do

	func_dir=${dir}/${subject}/${func_dir_name}
	func_reg_dir=${func_dir}/reg
	anat_dir=${dir}/${subject}/${anat_dir_name}
	anat_reg_dir=${anat_dir}/${reg_dir_name}
	if [ ${global_signal_removal} = 'true' ]
	then
		res_dir=${func_dir}/gs-removal
        	vmhc_dir=${func_dir}/VMHC-gs
	else
		res_dir=${func_dir}
        	vmhc_dir=${func_dir}/VMHC
	fi

	echo --------------------------
	echo running subject ${subject}
	echo --------------------------

	## check if func_dir is present
	if [ ! -d ${func_dir} ]
	then
    		echo SUBJECT ${subject} has no ${func}
    		continue;
	fi
	
	## make vmhc directory
        mkdir -p ${vmhc_dir}; cd ${vmhc_dir}

	## check if vmhc is already present, if not run subject
	if [ -f ${vmhc_dir}/VMHC_sm${fwhm}.nii.gz -a -f ${vmhc_dir}/VMHC_sm${fwhm}_Zmap.nii.gz -a -f ${vmhc_dir}/VMHC_sm${fwhm}_Zstat.nii.gz ]
	then
    		echo SUBJECT ${subject} already has VMHC images
    		echo SUBJECT ${subject} SKIPPED
    		continue;
	fi

	echo using image registered to symmetrical standard
	echo starting registration
	if [ ! -f ${anat_reg_dir}/highres2symmstandard_warp.nii.gz ]
	then				
        	## Linear registration of T1 --> symmetric standard
		echo Flirting T1 to symmetrical standard brain
	    	flirt -ref ${symm_standard_brain} -in ${anat_reg_dir}/highres_rpi.nii.gz -out ${anat_reg_dir}/highres_rpi2symmstandard.nii.gz -omat ${anat_reg_dir}/highres_rpi2symmstandard.mat -cost corratio -searchcost corratio -dof 12 -interp trilinear
        	## Create mat file for conversion from symmstandard to highres
        	convert_xfm -omat ${anat_reg_dir}/highres2symmstandard.mat -concat ${anat_reg_dir}/highres_rpi2symmstandard.mat ${anat_reg_dir}/reorient2rpi.mat
        	convert_xfm -inverse -omat ${anat_reg_dir}/symmstandard2highres.mat ${anat_reg_dir}/highres2symmstandard.mat
		## Perform nonlinear registration (higres to standard) to symmetric standard brain
		echo Fnirting T1 to symmetrical standard brain
        	fnirt --in=${anat_reg_dir}/highres_head.nii.gz --aff=${anat_reg_dir}/highres2symmstandard.mat --cout=${anat_reg_dir}/highres2symmstandard_warp --iout=${anat_reg_dir}/fnirt_highres2symmstandard --jout=${anat_reg_dir}/highres2symmstandard_jac --ref=${symm_standard} --refmask=${symm_standard_mask} --warpres=10,10,10 > ${anat_reg_dir}/warnings.vmhc.fnirt
        	if [ -s ${anat_reg_dir}/warnings.vmhc.fnirt ]
        	then
                	mv ${anat_reg_dir}/fnirt_highres2symmstandard.nii.gz ${anat_reg_dir}/fnirt_highres2symmstandard_wres10.nii.gz
                	fnirt --in=${anat_reg_dir}/highres_head.nii.gz --aff=${anat_reg_dir}/highres2symmstandard.mat --cout=${anat_reg_dir}/highres2symmstandard_warp --iout=${anat_reg_dir}/fnirt_highres2symmstandard --jout=${anat_reg_dir}/highres2symmstandard_jac --ref=${symm_standard} --refmask=${symm_standard_mask} --warpres=20,20,20
        	else
                	rm -v ${anat_reg_dir}/warnings.vmhc.fnirt
        	fi
	fi

	if [ ! -f ${res_dir}/${rest}_pp_sm${fwhm}.nii.gz ]
	then
		echo Please run functional preprocessing first ...
	else
		# 0. Apply nonlinear registration (func to standard)
		echo Applying warp to ${rest}_pp
		applywarp --ref=${symm_standard} --in=${res_dir}/${rest}_pp_sm${fwhm}.nii.gz --out=${vmhc_dir}/${rest}_sm${fwhm}_res2symmstandard.nii.gz --warp=${anat_reg_dir}/highres2symmstandard_warp.nii.gz --premat=${func_reg_dir}/example_func2highres.mat
		## 1. copy and L/R swap file
		echo swapping file
		fslswapdim ${vmhc_dir}/${rest}_sm${fwhm}_res2symmstandard.nii.gz -x y z tmp_LRflipped.nii.gz
		## 2. caculate vmhc
		echo Calculating pearson correlation between res2standard and flipped res2standard
		3dTcorrelate -pearson -polort -1 -prefix VMHC_sm${fwhm}.nii.gz ${vmhc_dir}/${rest}_sm${fwhm}_res2symmstandard.nii.gz tmp_LRflipped.nii.gz	
		## 3. Fisher Z transform map
		3dcalc -a VMHC_sm${fwhm}.nii.gz -expr 'log((1+a)/(1-a))/2' -prefix VMHC_sm${fwhm}_Zmap.nii.gz
		if [ ${fwhm} -eq 0 ]
		then
			mri_fwhm --i VMHC_sm${fwhm}_Zmap.nii.gz --o VMHC_sm${fwhm}_Zmap.nii.gz --smooth-only --fwhm 6 --mask ${hemi_standard_mask}
		else
			fslmaths VMHC_sm${fwhm}_Zmap.nii.gz -mas ${hemi_standard_mask} VMHC_sm${fwhm}_Zmap.nii.gz
		fi
		## 4. Z statistic map
		nvols=$( fslnvols tmp_LRflipped.nii.gz )
		echo ${nvols} volumes... 
		3dcalc -a VMHC_sm${fwhm}_Zmap.nii.gz -expr 'a*sqrt('${nvols}'-3)' -prefix VMHC_sm${fwhm}_Zstat.nii.gz
		ln -s VMHC_sm${fwhm}_Zmap.nii.gz fnirt_VMHC_sm${fwhm}_Zmap.nii.gz #metric name is VMHC_sm${fwhm}
		## Clean up
		echo cleaning up
		rm -rfv tmp*
	fi
## END OF SUBJECT LOOP
done
