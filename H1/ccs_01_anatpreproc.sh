#!/usr/bin/env bash

##########################################################################################################################
## CCS SCRIPT TO PREPROCESS THE ANATOMICAL SCAN (INTEGRATE AFNI/FSL/FREESURFER)
##
## R-fMRI master: Xi-Nian Zuo.
## 
## Email: zuoxn@psych.ac.cn or zuoxinian@gmail.com.
##
##########################################################################################################################

## subject
subject=$1
## analysisdirectory
dir=$2
## name of the anatomical scan
anat=$3
## name of anat directory
anat_dir_name=$4
## if use sanlm denoised anat
sanlm_denoised=$5
# if multiple scans
num_scans=$6
## if use g-cut
gcut=$7
## directory setup
CCSDIR=$8
anat_dir=${dir}/${subject}/${anat_dir_name}
SUBJECTS_DIR=${dir} #FREESURFER SETUP

if [ $# -lt 8 ];
then
        echo -e "\033[47;35m Usage: $0 subject analysis_dir anat_name anat_dir_name sanlm_denoised num_scans gcut ccs_dir \033[0m"
        exit
fi

echo --------------------------------------
echo !!!! PREPROCESSING ANATOMICAL SCAN!!!!
echo --------------------------------------

cwd=$( pwd ) ; cd ${anat_dir} 
bet_thr_tight=0.3 ; bet_thr_loose=0.1

## 1. FS stage-1
echo "Preparing data for ${sub} in freesurfer ..."
mkdir -p ${SUBJECTS_DIR}/${subject}/mri/orig
if [[ "${sanlm_denoised}" = "true" ]] 
then
	if [ ${num_scans} -eq 1 ]
	then
		rm -v ${anat}1_sanlm.nii.gz
		ln -s ${anat}_sanlm.nii.gz ${anat}1_sanlm.nii.gz
	fi
	for (( n=1; n <= ${num_scans}; n++ ))
	do
		3drefit -deoblique ${anat_dir}/${anat}${n}_sanlm.nii.gz
		mri_convert --in_type nii ${anat}${n}_sanlm.nii.gz ${SUBJECTS_DIR}/${subject}/mri/orig/00${n}.mgz
	done	
else
	if [ ${num_scans} -eq 1 ]
        then
		rm -v ${anat}1.nii.gz
                ln -s ${anat}.nii.gz ${anat}1.nii.gz
        fi
	for (( n=1; n <= ${num_scans}; n++ ))
       	do
		3drefit -deoblique ${anat_dir}/${anat}${n}.nii.gz
		mri_convert --in_type nii ${anat}${n}.nii.gz ${SUBJECTS_DIR}/${subject}/mri/orig/00${n}.mgz
	done
fi
echo "Auto reconstruction stage in Freesurfer (Take half hour ...)"
if [ ${gcut} = 'true' ]; then
	recon-all -s ${subject} -autorecon1 -notal-check -clean-bm -gcut -no-isrunning -noappend
else
	recon-all -s ${subject} -autorecon1 -notal-check -clean-bm -no-isrunning -noappend
fi
## Do other processing in VCHECK directory
mkdir -p vcheck ; cd vcheck
echo "Preparing extracted brain for FSL registration ..."
mri_convert -it mgz ${SUBJECTS_DIR}/${subject}/mri/brainmask.mgz -ot nii brainmask.nii.gz
mri_convert -it mgz ${SUBJECTS_DIR}/${subject}/mri/T1.mgz -ot nii T1.nii.gz

## 2. Reorient to fsl-friendly space
echo "Reorienting ${subject} anatomical"
rm -f brain_fs.nii.gz
3dresample -orient RPI -inset brainmask.nii.gz -prefix brain_fs.nii.gz
fslmaths brain_fs.nii.gz -abs -bin brain_fs_mask.nii.gz
rm -f head_fs.nii.gz
3dresample -orient RPI -inset T1.nii.gz -prefix head_fs.nii.gz
rm -rf brainmask.nii.gz ; 
for (( n=1; n <= ${num_scans}; n++ ))
do
	rm -f ${SUBJECTS_DIR}/${subject}/mri/orig/00${n}.mgz
done

## 3. Final BET
echo "Simply register the T1 image to the MNI152 standard space ..."
flirt -in head_fs.nii.gz -ref ${FSLDIR}/data/standard/MNI152_T1_1mm.nii.gz -out tmp_head_fs2standard.nii.gz -omat tmp_head_fs2standard.mat -bins 256 -cost corratio -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 12  -interp trilinear
convert_xfm -omat tmp_standard2head_fs.mat -inverse tmp_head_fs2standard.mat
echo "Perform a tight brain extraction ..."
bet tmp_head_fs2standard.nii.gz tmp.nii.gz -f ${bet_thr_tight} -m
fslmaths tmp_mask.nii.gz -mas ${CCSDIR}/templates/MNI152_T1_1mm_first_brain_mask.nii.gz tmp_mask.nii.gz
flirt -in tmp_mask.nii.gz -applyxfm -init tmp_standard2head_fs.mat -out brain_fsl_mask_tight.nii.gz -paddingsize 0.0 -interp nearestneighbour -ref head_fs.nii.gz
fslmaths brain_fs_mask.nii.gz -mul brain_fsl_mask_tight.nii.gz -bin brain_mask_tight.nii.gz
fslmaths head_fs.nii.gz -mas brain_fsl_mask_tight.nii.gz brain_fsl_tight.nii.gz
fslmaths head_fs.nii.gz -mas brain_mask_tight.nii.gz brain_tight.nii.gz
rm -f tmp.nii.gz
3dresample -master T1.nii.gz -inset brain_tight.nii.gz -prefix tmp.nii.gz
mri_convert --in_type nii tmp.nii.gz ${SUBJECTS_DIR}/${subject}/mri/brain_tight.mgz
mri_mask ${SUBJECTS_DIR}/${subject}/mri/T1.mgz ${SUBJECTS_DIR}/${subject}/mri/brain_tight.mgz ${SUBJECTS_DIR}/${subject}/mri/brainmask.tight.mgz
echo "Perform a loose brain extraction ..."
bet tmp_head_fs2standard.nii.gz tmp.nii.gz -f ${bet_thr_loose} -m
fslmaths tmp_mask.nii.gz -mas ${CCSDIR}/templates/MNI152_T1_1mm_first_brain_mask.nii.gz tmp_mask.nii.gz
flirt -in tmp_mask.nii.gz -applyxfm -init tmp_standard2head_fs.mat -out brain_fsl_mask_loose.nii.gz -paddingsize 0.0 -interp nearestneighbour -ref head_fs.nii.gz
fslmaths brain_fs_mask.nii.gz -mul brain_fsl_mask_loose.nii.gz -bin brain_mask_loose.nii.gz
fslmaths head_fs.nii.gz -mas brain_fsl_mask_loose.nii.gz brain_fsl_loose.nii.gz
fslmaths head_fs.nii.gz -mas brain_mask_loose.nii.gz brain_loose.nii.gz
rm -f tmp.nii.gz
3dresample -master T1.nii.gz -inset brain_loose.nii.gz -prefix tmp.nii.gz
mri_convert --in_type nii tmp.nii.gz ${SUBJECTS_DIR}/${subject}/mri/brain_loose.mgz
mri_mask ${SUBJECTS_DIR}/${subject}/mri/T1.mgz ${SUBJECTS_DIR}/${subject}/mri/brain_loose.mgz ${SUBJECTS_DIR}/${subject}/mri/brainmask.loose.mgz
## 4. Quality check
rm -f tmp* T1.nii.gz
overlay 1 1 head_fs.nii.gz -a brain_fs_mask.nii.gz 1 1 rendered_mask.nii.gz
#FS BET
slicer rendered_mask -S 10 1200 skull_fs_strip.png
title=${subject}.ccs.anat.fs.skullstrip
convert -font helvetica -fill white -pointsize 36 -draw "text 30,50 '$title'" skull_fs_strip.png skull_fs_strip.png
#FS/FSL tight BET
rm -f rendered_mask.nii.gz
overlay 1 1 head_fs.nii.gz -a brain_mask_tight.nii.gz 1 1 rendered_mask.nii.gz
slicer rendered_mask -S 10 1200 skull_tight_strip.png
title=${subject}.ccs.anat.skullstrip
convert -font helvetica -fill white -pointsize 36 -draw "text 30,50 '$title'" skull_tight_strip.png skull_tight_strip.png
rm -f rendered_mask.nii.gz
fslmaths brain_fs_mask.nii.gz -sub brain_mask_tight.nii.gz -abs -bin diff_mask_tight.nii.gz
overlay 1 1 head_fs.nii.gz -a diff_mask_tight.nii.gz 1 1 rendered_mask.nii.gz
slicer rendered_mask -S 10 1200 skull_tight_strip_diff.png
title=${subject}.ccs.anat.skullstrip.diff
convert -font helvetica -fill white -pointsize 36 -draw "text 30,50 '$title'" skull_tight_strip_diff.png skull_tight_strip_diff.png
rm -f rendered_mask.nii.gz
#FS/FSL loose BET
rm -f rendered_mask.nii.gz
overlay 1 1 head_fs.nii.gz -a brain_mask_loose.nii.gz 1 1 rendered_mask.nii.gz
slicer rendered_mask -S 10 1200 skull_loose_strip.png
title=${subject}.ccs.anat.skullstrip
convert -font helvetica -fill white -pointsize 36 -draw "text 30,50 '$title'" skull_loose_strip.png skull_loose_strip.png
rm -f rendered_mask.nii.gz
fslmaths brain_fs_mask.nii.gz -sub brain_mask_loose.nii.gz -abs -bin diff_mask_loose.nii.gz
overlay 1 1 head_fs.nii.gz -a diff_mask_loose.nii.gz 1 1 rendered_mask.nii.gz
slicer rendered_mask -S 10 1200 skull_loose_strip_diff.png
title=${subject}.ccs.anat.skullstrip.diff
convert -font helvetica -fill white -pointsize 36 -draw "text 30,50 '$title'" skull_loose_strip_diff.png skull_loose_strip_diff.png
rm -f rendered_mask.nii.gz

cd ${cwd}
