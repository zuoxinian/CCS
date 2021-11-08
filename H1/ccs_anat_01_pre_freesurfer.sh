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
anat_name=T1

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
cd ${anat_dir}
#1.reorient to RPI

if [ ! -f ${anat_dir}/T1_ro.nii.gz ]
then
	echo "############### Reorient image ####################"
	3dresample -orient RPI -inset T1.nii.gz -prefix T1_ro.nii.gz
fi



#2.crop the image


if [ ! -f ${anat_dir}/T1_crop.nii.gz ]
then
	echo "############### Croping image ####################"
	robustfov -i T1_ro -r T1_crop
fi

#3.Using SANLM to denoise image

if [ ! -f ${anat_dir}/T1_crop_sanlm.nii.gz ]
then
	echo "############### desonising image #################"
	mkdir -p ${anat_dir}/denoise/
	mri_convert -i ${anat_dir}/T1_crop.nii.gz -o ${anat_dir}/denoise/T1_crop.nii
	matlab  -nodesktop -nosplash -nojvm -r "data='${anat_dir}/denoise/T1_crop.nii';cat_vol_sanlm(struct('data',data));quit"
	mri_convert -i ${anat_dir}/denoise/sanlm_T1_crop.nii -o ${anat_dir}/T1_crop_sanlm.nii.gz
	rm -rf ${anat_dir}/denoise/
fi

#4. deepbet to making brain mask
if [ ! -f ${anat_dir}/T1_crop_sanlm_pre_mask.nii.gz ]
then
	echo "############# making mask by deep_bet ###############"
	#generating mask
	docker run -v ${anat_dir}:/data -v ${CCS_APP}/models:/Models -v ${anat_dir}:/output sandywangrest/deepbet muSkullStrip.py -in /data/T1_crop_sanlm.nii.gz -model /Models/model-04-epoch -out /output
	#create qc pics
	mkdir -p ${anat_dir}/qc
	overlay 1 1 ${anat_dir}/T1_crop_sanlm.nii.gz -a ${anat_dir}/T1_crop_sanlm_pre_mask.nii.gz 1 1 ${anat_dir}/qc/T1_rendermask.nii.gz
	slicer ${anat_dir}/qc/T1_rendermask.nii.gz -S 10 1200 ${anat_dir}/qc/mask.png
	title=${subject}.anat.UNet.skullstrip
	convert -font helvetica -fill white -pointsize 36 -draw "text 30,50 '$title'" ${anat_dir}/qc/mask.png ${anat_dir}/qc/mask.png
	rm -f ${anat_dir}/qc/T1_rendermask.nii.gz

fi



#echo "######################### Running FreeSurfer First Stage ########################"
#convert T1_crop_sanlm to 001.mgz
#mkdir -p ${SUBJECTS_DIR}/${subject}/mri/orig
#mri_convert -i ${anat_dir}/T1_crop_sanlm.nii.gz -o ${SUBJECTS_DIR}/${subject}/mri/orig/001.mgz

##first stage of recon-all
#recon-all -s ${subject} -autorecon1 -gcut -parallel

##convert brainmask
#echo "################# Changing orig brainmask by the deep_bet brainmask ###################"
#mri_convert ${SUBJECTS_DIR}/${subject}/mri/T1.mgz ${SUBJECTS_DIR}/${subject}/mri/T1.nii.gz
#3dresample -master ${SUBJECTS_DIR}/${subject}/mri/T1.nii.gz -inset ${anat_dir}/#T1_crop_sanlm_pre_mask.nii.gz -prefix ${SUBJECTS_DIR}/${subject}/mri/mask.nii.gz
#fslmaths ${SUBJECTS_DIR}/${subject}/mri/T1.nii.gz -mas ${SUBJECTS_DIR}/${subject}/mri/mask.nii.gz #${SUBJECTS_DIR}/${subject}/mri/brainmask.nii.gz
#mv ${SUBJECTS_DIR}/${subject}/mri/brainmask.mgz ${SUBJECTS_DIR}/${subject}/mri/#brainmask.fsinit.mgz
#mri_convert -i ${SUBJECTS_DIR}/${subject}/mri/brainmask.nii.gz -o ${SUBJECTS_DIR}/${subject}/mri/#brainmask.mgz

##recon2 3
#recon-all -s ${subject} -autorecon2 -autorecon3 -parallel


