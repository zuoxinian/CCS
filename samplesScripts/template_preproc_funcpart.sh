##Directory
CCS_DIR=/your_project_path/CCS
SUBJECTS_DIR=/your_project_path/FreeSurfer60/
##PARAMETERS
rest_dir_name=rest
rest_name=rest
TR=2
numDropping=5 ## 10 seconds
sliceOrder=alt+z
FWHM=6
##SUBJECT
subject=CCSsubjectname 
echo ${subject}

CCS_APP=/brain/zuoxinian/LCBT_app/CCS_SCRIPTS
##PREPROCESSING
${CCS_APP}/BashScripts/ccs_01_funcpreproc.sh ${subject} ${CCS_DIR} ${rest_name} ${numDropping} ${TR} anat ${rest_dir_name} ${sliceOrder} 

#PreBBR
fslroi ${CCS_DIR}/${subject}/${rest_dir_name}/${rest_name}.nii.gz ${CCS_DIR}/${subject}/${rest_dir_name}/${rest_name}_fsimage.nii.gz 0 1
first_image=${CCS_DIR}/${subject}/${rest_dir_name}/${rest_name}_fsimage.nii.gz

##BBR
${CCS_APP}/BashScripts/ccs_02_funcbbregister.sh ${subject} ${CCS_DIR} ${rest_dir_name} ${rest_name} fsaverage5 ${SUBJECTS_DIR} ${first_image}

##SEGMENTATION
${CCS_APP}/BashScripts/ccs_03_funcsegment.sh ${subject} ${CCS_DIR} ${rest_name} anat ${rest_dir_name} ${SUBJECTS_DIR}

##AROMA
${CCS_APP}/BashScripts/ccs_04_funcAROMA.sh ${subject} ${CCS_DIR} anat  ${rest_dir_name} ${rest_name} ${CCS_APP}/extool/ICA-AROMA ${FWHM} 0

##NUISANCE
${CCS_APP}/BashScripts/ccs_04_funcnuisance.sh ${subject} ${CCS_DIR} ${rest_name} ${rest_dir_name} false
##FINAL
${CCS_APP}/BashScripts/ccs_05_funcpreproc_nofilt_cortex.sh ${subject} ${CCS_DIR} ${rest_name} anat ${rest_dir_name} fsaverage5  ${SUBJECTS_DIR}
