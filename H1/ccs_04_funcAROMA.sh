#!/usr/bin/env bash

##########################################################################################################################
## CCS SCRIPT TO DO IMAGE REGISTRATION (FLIRT/FNIRT)
##
## !!!!!*****ALWAYS CHECK YOUR REGISTRATIONS*****!!!!!
##
## R-fMRI master: Xi-Nian Zuo. Nov. 27, 2015, Institute of Psychology, CAS.
##
## Email: zuoxn@psych.ac.cn or zuoxinian@gmail.com.
##########################################################################################################################

## subject
subject=$1
## analysisdir
dir=$2
## name of anatomical directory
anat_dir_name=$3
## name of functional directory
func_dir_name=$4
## rest name
rest_name=$5
## aroma directory
pyAROMA=$6
##
fwhm=$7
## numbers of IC
num_ICs=$8

if [ $# -lt 7 ];
then
        echo -e "\033[47;35m Usage: $0 subject analysis_dir anat_dir_name func_dir_name rest_name pyAROMA fwhm \033[0m"
        exit
fi

echo -----------------------
echo !!!! Run ICA_AROMA !!!!
echo -----------------------

reg_dir=reg
## 0. Directory setup
anat_dir=${dir}/${subject}/${anat_dir_name}
anat_reg_dir=${anat_dir}/${reg_dir}
func_dir=${dir}/${subject}/${func_dir_name}
func_reg_dir=${func_dir}/${reg_dir}
aroma_dir=${func_dir}/aroma

## 2. Prepare the registration files
cd ${func_reg_dir}
cp flirt.mtx example_func2highres.mat
convert_xfm -inverse -omat highres2example_func.mat example_func2highres.mat
convert_xfm -omat example_func2standard.mat -concat ${anat_reg_dir}/highres2standard.mat example_func2highres.mat
convert_xfm -inverse -omat standard2example_func.mat example_func2standard.mat

#mkdir -p ${aroma_dir} ; cd ${aroma_dir}

## 3. Perform sptial smoothing for aroma. NOTICE, the smoothed image is made only for extracting ICA-based components, nuisance related components are regressed out from unsmoothed data.
mri_fwhm --i ${func_dir}/${rest_name}_gms.nii.gz --o ${func_dir}/${rest_name}_gms_sm6.nii.gz --smooth-only --fwhm ${fwhm} --mask ${func_dir}/${rest_name}_pp_mask.nii.gz

## 4. Run ICA_AROMA
if [ $num_ICs -gt 0 ]
then

        python ${pyAROMA}/ICA_AROMA.py -in ${func_dir}/${rest_name}_gms_sm6.nii.gz -out ${aroma_dir} -mc ${func_dir}/${rest_name}_mc.par -affmat ${func_reg_dir}/example_func2standard.mat -den no -dim ${num_ICs} -m ${func_dir}/${rest_name}_pp_mask.nii.gz
else
        python ${pyAROMA}/ICA_AROMA.py -in ${func_dir}/${rest_name}_gms_sm6.nii.gz -out ${aroma_dir} -mc ${func_dir}/${rest_name}_mc.par -affmat ${func_reg_dir}/example_func2standard.mat -den no -m ${func_dir}/${rest_name}_pp_mask.nii.gz
fi
## Regressing out nuisance related components from unsmoothed data.
fsl_regfilt --in=${func_dir}/${rest_name}_gms.nii.gz --design=${aroma_dir}/melodic.ica/melodic_mix --filter="`cat ${aroma_dir}/classified_motion_ICs.txt`" --out=${aroma_dir}/denoised_func_data_nonaggr_sm0.nii.gz

## 5. END
mv ${aroma_dir}/denoised_func_data_nonaggr_sm0.nii.gz ${func_dir}/${rest_name}_aroma.nii.gz

cd ${cwd}
