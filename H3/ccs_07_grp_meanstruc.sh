#!/usr/bin/env bash

##########################################################################################################################
## CCS SCRIPT TO GENERATE THE GROUP AVERAGE T1
##
## Modified by R-fMRI master: Xi-Nian Zuo. Dec. 07, 2010, Institute of Psychology, CAS.
## Email: zuoxn@psych.ac.cn.
##
##########################################################################################################################

## full/path/to/site
dir=$1
## full/path/to/site/subject_list
subject_list=$2
## name of anatomical directory
anat_dir_name=$3
## template directory
template_dir=$4
## template name without extension
template_name=$5
## template spatial resolution
spr=$6
## name of reg dir
reg_dir_name=$7

## Standard template setup
standard_head=${FSLDIR}/data/standard/MNI152_T1_${spr}.nii.gz
standard_head_2mm=${FSLDIR}/data/standard/MNI152_T1_2mm.nii.gz

if [ $# -lt 6 ];
then
        echo -e "\033[47;35m Usage: $0 analysis_dir subject_list anat_dir_name template_dir template_name spatial_res \033[0m"
        exit
fi

echo -----------------------------------------
echo !!!! MAKING STUDY SPECIFIC TEMPLATE !!!!
echo -----------------------------------------


mkdir -p ${template_dir} ; cd ${template_dir}
if [ "${spr}" != "2mm" ]
then
	fslmaths ${standard_head} -sub ${standard_head} ${template_dir}/${template_name}_${spr}.nii.gz -odt double
	fslmaths ${standard_head} -sub ${standard_head} ${template_dir}/${template_name}_${spr}_brain.nii.gz -odt double
	fslmaths ${template_dir}/${template_name}_${spr}.nii.gz -add 1 ${template_dir}/${template_name}_${spr}_brain_mask.nii.gz
fi
fslmaths ${standard_head_2mm} -sub ${standard_head_2mm} ${template_dir}/${template_name}_2mm.nii.gz -odt double
fslmaths ${standard_head_2mm} -sub ${standard_head_2mm} ${template_dir}/${template_name}_2mm_brain.nii.gz -odt double
fslmaths ${template_dir}/${template_name}_2mm.nii.gz -add 1 ${template_dir}/${template_name}_2mm_brain_mask.nii.gz

if [ $# -lt 7 ];
then
        reg_dir_name=reg
fi

k=0 #counter

for subject in `cat ${subject_list}`
do
  echo "Processing ${subject} ..."
  anat_dir=${dir}/${subject}/${anat_dir_name}
  anat_reg_dir=${anat_dir}/${reg_dir_name}
  if [ "${spr}" != "2mm" ]
  then
	#head
 	applywarp --ref=${standard_head} --in=${anat_reg_dir}/highres_head.nii.gz --warp=${anat_reg_dir}/highres2standard_warp.nii.gz --out=tmp.nii.gz
      	fslmaths tmp.nii.gz -add ${template_dir}/${template_name}_${spr}.nii.gz ${template_dir}/${template_name}_${spr}.nii.gz -odt double
	#brain
	applywarp --ref=${standard_head} --in=${anat_reg_dir}/highres.nii.gz --warp=${anat_reg_dir}/highres2standard_warp.nii.gz --out=tmp.nii.gz
        fslmaths tmp.nii.gz -add ${template_dir}/${template_name}_${spr}_brain.nii.gz ${template_dir}/${template_name}_${spr}_brain.nii.gz -odt double
	fslmaths tmp.nii.gz -bin tmp_mask.nii.gz
	fslmaths ${template_dir}/${template_name}_${spr}_brain_mask.nii.gz -mul tmp_mask.nii.gz ${template_dir}/${template_name}_${spr}_brain_mask.nii.gz
  fi
  #head_2mm
  fslmaths ${anat_reg_dir}/fnirt_highres2standard.nii.gz -add ${template_dir}/${template_name}_2mm.nii.gz ${template_dir}/${template_name}_2mm.nii.gz -odt double
  #brain_2mm
  applywarp --ref=${standard_head_2mm} --in=${anat_reg_dir}/highres.nii.gz --warp=${anat_reg_dir}/highres2standard_warp.nii.gz --out=tmp.nii.gz
  fslmaths tmp.nii.gz -add ${template_dir}/${template_name}_2mm_brain.nii.gz ${template_dir}/${template_name}_2mm_brain.nii.gz -odt double
  fslmaths tmp.nii.gz -bin tmp_mask.nii.gz
  fslmaths ${template_dir}/${template_name}_2mm_brain_mask.nii.gz -mul tmp_mask.nii.gz ${template_dir}/${template_name}_2mm_brain_mask.nii.gz
  let k=k+1
done

if [ "${spr}" != "2mm" ]
then
	fslmaths ${template_dir}/${template_name}_${spr}.nii.gz -div ${k} ${template_dir}/${template_name}_${spr}.nii.gz -odt int
	fslmaths ${template_dir}/${template_name}_${spr}_brain.nii.gz -div ${k} ${template_dir}/${template_name}_${spr}_brain.nii.gz -odt int
fi
fslmaths ${template_dir}/${template_name}_2mm.nii.gz -div ${k} ${template_dir}/${template_name}_2mm.nii.gz -odt int
fslmaths ${template_dir}/${template_name}_2mm_brain.nii.gz -div ${k} ${template_dir}/${template_name}_2mm_brain.nii.gz -odt int
###***** ALWAYS CHECK YOUR TEMPLATE!!! YOU WILL EXPERIENCE PROBLEMS IF YOUR OUTPUT FILES ARE FROM HUGE NUMBER OF SUBJECTS *****###

