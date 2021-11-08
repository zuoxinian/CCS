#!/usr/bin/env bash
########this script run ccs_anat_preproc###########
#there are three inputs 
# The first step of this script is to run on bash will move to python eventually
# 1.CCS_DIR
# 2.SUBJECTS_DIR
# 3.subject
######################################################

#set dirs
CCS_DIR=$1
SUBJECTS_DIR=$2
subject=$3
anat_dir=${CCS_DIR}/${subject}/anat
reg_dir=${anat_dir}/reg
seg_dir=${anat_dir}/segment
mkdir -p ${reg_dir} ${seg_dir}

if [ $# -lt 3 ]; 
then
    	echo -e "\033[47;35m Usage: $0 CCS_DIR SUBJECTS_DIR subject \033[0m"
	exit
fi


#generate copy brainmask


#copy orig.migz
if [ ! -f ${anat_dir}/T1_crop_sanlm_fs.nii.gz ]
then
	mri_convert -it mgz ${SUBJECTS_DIR}/${subject}/mri/orig.mgz -ot nii ${anat_dir}/T1_crop_sanlm_fs.nii.gz
fi

if [ ! -f ${seg_dir}/brainmask.nii.gz ]
then
    mri_convert -it mgz ${SUBJECTS_DIR}/${subject}/mri/brainmask.mgz -ot nii ${seg_dir}/brainmask.nii.gz
fi

## 1. Prepare anatomical images
if [ -f ${reg_dir}/highres_head.nii.gz ]
then
    rm -v ${reg_dir}/highres_head.nii.gz
fi


mv ${anat_dir}/T1_crop_sanlm_fs.nii.gz ${reg_dir}/highres_head.nii.gz
fslmaths ${seg_dir}/brainmask.nii.gz -thr 2 ${seg_dir}/brainmask.nii.gz #clean voxels manually edited in freesurfer (assigned value 1)
fslmaths ${reg_dir}/highres_head.nii.gz -mas ${seg_dir}/brainmask.nii.gz ${reg_dir}/highres.nii.gz

cd ${reg_dir}
## 1. copy standard (We provide two reg pipelines: FSL and Freesurfer, the latter was done in Recon-all automatically)
standard_head=${FSLDIR}/data/standard/MNI152_T1_2mm.nii.gz
standard=${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz
standard_mask=${FSLDIR}/data/standard/MNI152_T1_2mm_brain_mask_dil.nii.gz
## 2. FLIRT T1->STANDARD
echo "########################## Performing FLIRT T1 -> STANDARD #################################"
fslreorient2std highres.nii.gz highres_rpi.nii.gz
fslreorient2std highres_head.nii.gz highres_head_rpi.nii.gz # not used, just test for future use
flirt -ref ${standard} -in highres_rpi -out highres_rpi2standard -omat highres_rpi2standard.mat -cost corratio -searchcost corratio -dof 12 -interp trilinear
## 3. Create mat file for conversion from standard to high res
fslreorient2std highres.nii.gz > reorient2rpi.mat
convert_xfm -omat highres2standard.mat -concat highres_rpi2standard.mat reorient2rpi.mat
convert_xfm -inverse -omat standard2highres.mat highres2standard.mat

## 3. FNIRT
echo "########################## Performing nolinear registration ... #################################"
fnirt --in=highres_head --aff=highres2standard.mat --cout=highres2standard_warp --iout=fnirt_highres2standard --jout=highres2standard_jac --config=T1_2_MNI152_2mm --ref=${standard_head} --refmask=${standard_mask} --warpres=10,10,10 > warnings.fnirt
if [ -s ${reg_dir}/warnings.fnirt ]
then
	mv fnirt_highres2standard.nii.gz fnirt_highres2standard_wres10.nii.gz
	fnirt --in=highres_head --aff=highres2standard.mat --cout=highres2standard_warp --iout=fnirt_highres2standard --jout=highres2standard_jac --config=T1_2_MNI152_2mm --ref=${standard_head} --refmask=${standard_mask} --warpres=20,20,20
else
	rm -v warnings.fnirt
fi

cd ${cwd}
