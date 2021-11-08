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

if [ $# -lt 3 ]; 
then
    	echo -e "\033[47;35m Usage: $0 CCS_DIR SUBJECTS_DIR subject \033[0m"
	exit
fi

#test if file existence
T1image=${CCS_DIR}/${subject}/anat/T1.nii.gz
if [ ! -f ${T1image} ]
then
	echo "Couldn't find T1 image ${T1image} please check your data"
	exit
fi

################################## Preprocesing #############################

echo "######################### Running FreeSurfer First Stage ########################"
#convert T1_crop_sanlm to 001.mgz
mkdir -p ${SUBJECTS_DIR}/${subject}/mri/orig
mri_convert -i ${anat_dir}/T1_crop_sanlm.nii.gz -o ${SUBJECTS_DIR}/${subject}/mri/orig/001.mgz

#first stage of recon-all
recon-all -s ${subject} -autorecon1 -gcut -parallel

##convert brainmask
echo "################# Changing orig brainmask by the deep_bet brainmask ###################"
mri_convert ${SUBJECTS_DIR}/${subject}/mri/T1.mgz ${SUBJECTS_DIR}/${subject}/mri/T1.nii.gz
3dresample -master ${SUBJECTS_DIR}/${subject}/mri/T1.nii.gz -inset ${anat_dir}/T1_crop_sanlm_pre_mask.nii.gz -prefix ${SUBJECTS_DIR}/${subject}/mri/mask.nii.gz
fslmaths ${SUBJECTS_DIR}/${subject}/mri/T1.nii.gz -mas ${SUBJECTS_DIR}/${subject}/mri/mask.nii.gz ${SUBJECTS_DIR}/${subject}/mri/brainmask.nii.gz
mv ${SUBJECTS_DIR}/${subject}/mri/brainmask.mgz ${SUBJECTS_DIR}/${subject}/mri/brainmask.fsinit.mgz
mri_convert -i ${SUBJECTS_DIR}/${subject}/mri/brainmask.nii.gz -o ${SUBJECTS_DIR}/${subject}/mri/brainmask.mgz

##recon2 3
recon-all -s ${subject} -autorecon2 -autorecon3 -parallel

##freesurfer
mkdir -p ${anat_dir}/segment/
mri_binarize --i ${SUBJECTS_DIR}/${subject}/mri/aseg.mgz --o ${anat_dir}/segment/segment_wm.nii.gz --match 2 41 7 46 251 252 253 254 255 --erode 1
mri_binarize --i ${SUBJECTS_DIR}/${subject}/mri/aseg.mgz --o ${anat_dir}/segment/segment_csf.nii.gz --match 4 5 43 44 31 63 --erode 1