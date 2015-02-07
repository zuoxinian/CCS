#!/usr/bin/env bash

##########################################################################################################################
## CCS SCRIPT TO DO IMAGE REGISTRATION (FLIRT/FNIRT)
##
## R-fMRI master: Xi-Nian Zuo. Dec. 07, 2010, Institute of Psychology, CAS.
##
## Last Modified: Sept., 21, 2014.
## Email: zuoxn@psych.ac.cn or zuoxinian@gmail.com.
##########################################################################################################################

## subject
subject=$1
## analysisdir
dir=$2
## name of anatomical directory
anat_dir_name=$3
## name of anatomical registration directory
reg_fnirt=$4

if [ $# -lt 3 ];
then
        echo -e "\033[47;35m Usage: $0 subject analysis_dir anat_dir_name \033[0m"
        exit
fi

echo -----------------------------------------
echo !!!! RUNNING ANATOMICAL REGISTRATION !!!!
echo -----------------------------------------


## directory setup
if [ $# -lt 4 ];
then
        reg_fnirt=false
fi
anat_dir=${dir}/${subject}/${anat_dir_name}
anat_reg_dir=${anat_dir}/reg
anat_seg_dir=${anat_dir}/segment
### copy standard (We provide two reg pipelines: FSL and Freesurfer, the latter was done in Recon-all automatically)
standard_head=${FSLDIR}/data/standard/MNI152_T1_2mm.nii.gz
standard=${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz
standard_mask=${FSLDIR}/data/standard/MNI152_T1_2mm_brain_mask_dil.nii.gz

if [ ! -f ${anat_reg_dir}/highres2standard.mat ]
then
	mkdir -p ${anat_reg_dir} ; cd ${anat_reg_dir}

	## 1. Prepare anatomical images
	mri_convert -it mgz ${dir}/${subject}/mri/rawavg.mgz -ot nii tmp_head.nii.gz
	if [ -f ${anat_reg_dir}/highres_head.nii.gz ]
	then
		echo "Warning: Cleaning previously created highres_head image!"
		rm -v ${anat_reg_dir}/highres_head.nii.gz
	fi
	if [ ! -f ${anat_seg_dir}/brainmask.nii.gz ]
	then
		mkdir -p ${anat_seg_dir}
		mri_convert -it mgz ${dir}/${subject}/mri/brainmask.mgz -ot nii ${anat_seg_dir}/brainmask.nii.gz
       		mri_convert -it mgz ${dir}/${subject}/mri/T1.mgz -ot nii ${anat_seg_dir}/T1.nii.gz
	fi
	3dresample -master ${anat_seg_dir}/brainmask.nii.gz -rmode Linear -prefix ${anat_reg_dir}/highres_head.nii.gz -inset tmp_head.nii.gz
	fslmaths ${anat_seg_dir}/brainmask.nii.gz -thr 2 ${anat_seg_dir}/brainmask.nii.gz #clean voxels manually edited in freesurfer (assigned value 1)
	fslmaths highres_head.nii.gz -mas ${anat_seg_dir}/brainmask.nii.gz highres.nii.gz ; rm -v tmp_head.nii.gz

	## 2. FLIRT T1->STANDARD
	echo "Performing the linear affine registration: FLIRT ..."
	fslreorient2std highres.nii.gz highres_rpi.nii.gz
	flirt -ref ${standard} -in highres_rpi -out highres_rpi2standard -omat highres_rpi2standard.mat -cost corratio -searchcost corratio -dof 12 -interp trilinear
	## Create mat file for conversion from standard to high res
	fslreorient2std highres.nii.gz > reorient2rpi.mat
	convert_xfm -omat highres2standard.mat -concat highres_rpi2standard.mat reorient2rpi.mat 
	convert_xfm -inverse -omat standard2highres.mat highres2standard.mat
	## 3. FNIRT
	if [[ "${reg_fnirt}" = "true" ]]
	then
		echo "Performing nolinear registration ..."
		fnirt --in=highres_head --aff=highres2standard.mat --cout=highres2standard_warp --iout=fnirt_highres2standard --jout=highres2standard_jac --config=T1_2_MNI152_2mm --ref=${standard_head} --refmask=${standard_mask} --warpres=10,10,10 > warnings.fnirt
		if [ -s ${anat_reg_dir}/warnings.fnirt ]
		then
			mv fnirt_highres2standard.nii.gz fnirt_highres2standard_wres10.nii.gz
			fnirt --in=highres_head --aff=highres2standard.mat --cout=highres2standard_warp --iout=fnirt_highres2standard --jout=highres2standard_jac --config=T1_2_MNI152_2mm --ref=${standard_head} --refmask=${standard_mask} --warpres=20,20,20
		else
			rm -v warnings.fnirt
		fi
	else
		echo "As default in CCS, FNIRT-based nolinear registration was not performed."
	fi
else
	echo "The registration has been done for this subject!"
fi
## Output screeshots for quality control
if [ ! -f ${anat_reg_dir}/vcheck/check_flirt.png ]
then
        cd ${anat_reg_dir}; mkdir -p vcheck
        slicer highres_rpi.nii.gz -a vcheck/brainmask.png
        title=ccs.anat.qcp.skullstrip.final
        convert -font helvetica -fill white -pointsize 20 -draw "text 10,20 '$title'" vcheck/brainmask.png vcheck/brainmask.png
        slicer highres_rpi2standard.nii.gz -a vcheck/brainmask2mni152.png
        title=ccs.anat.qcp.skullstrip.mni152
        convert -font helvetica -fill white -pointsize 10 -draw "text 10,10 '$title'" vcheck/brainmask2mni152.png vcheck/brainmask2mni152.png
        slicer ${standard} -a vcheck/standard2mm.png
        title=ccs.anat.qcp.standard.mni152
        convert -font helvetica -fill white -pointsize 10 -draw "text 10,10 '$title'" vcheck/standard2mm.png vcheck/standard2mm.png
        pngappend vcheck/brainmask2mni152.png - vcheck/standard2mm.png vcheck/check_flirt.png
fi

cd ${cwd}
