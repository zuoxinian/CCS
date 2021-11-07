#!/usr/bin/env bash

##########################################################################################################################
## CCS SCRIPT TO DO REGRESS OUT NUISANCE COVARIATES FROM RESTING_STATE SCAN
## nuisance covariates are: global signal (option), white matter (WM, WHITE), CSF, and
## 6 motion parameters obtained during motion correction step (see lfcd_02_funcpreproc.sh)
##
## R-fMRI master: Xi-Nian Zuo.
## Email: zuoxn@psych.ac.cn or zuoxinian@gmail.com.
##########################################################################################################################

## subject
subject=$1
## analysisdirectory
dir=$2
## resting-state filename (no extension)
rest=$3
## name of func directory
func_dir_name=$4
## if use SVD averaged nuisances
svd=$5

## directory setup
func_dir=${dir}/${subject}/${func_dir_name}
func_reg_dir=${func_dir}/reg
func_segment_dir=${func_dir}/segment
nuisance_dir=${func_dir}/nuisance

if [ $# -lt 5 ];
then
        echo -e "\033[47;35m Usage: $0 subject analysis_dir rest_name func_dir_name svd \033[0m"
        exit
fi

echo --------------------------------------------
echo !!!! RUNNING NUISANCE SIGNAL REGRESSION !!!!
echo --------------------------------------------


## 1. Make nuisance directory
mkdir -p ${nuisance_dir}; cd ${nuisance_dir}

## 2. Extract signal for global, csf, and wm
if [ -f ${func_dir}/${rest}_aroma.nii.gz ]
then
    echo "Use ICA-AROMA denoised data ..."
    tmprest=${func_dir}/${rest}_aroma.nii.gz
else
    tmprest=${func_dir}/${rest}_gms.nii.gz
fi
## 3. Global
echo "Extracting global signal for ${subject}"
3dmaskave -mask ${func_segment_dir}/global_mask.nii.gz -quiet ${func_dir}/${rest}_gms.nii.gz > ${nuisance_dir}/global.1D

## 4. CSF
echo "Extracting signal from csf for ${subject}"
if [ -e ${func_dir}/csf_mask_fs.nii.gz ]
then
	3dmaskSVD -vnorm -mask ${func_dir}/csf_mask_fs.nii.gz -polort 0 ${func_dir}/${rest}_gms.nii.gz > ${nuisance_dir}/csf_qvec.1D
	3dmaskave -mask ${func_dir}/csf_mask_fs.nii.gz -quiet ${func_dir}/${rest}_gms.nii.gz > ${nuisance_dir}/csf.1D
fi
## 5. WM
echo "Extracting signal from white matter for ${subject}"
if [ -e ${func_dir}/wm_mask_fs.nii.gz ]
then
	3dmaskSVD -vnorm -mask ${func_dir}/wm_mask_fs.nii.gz -polort 0 ${func_dir}/${rest}_gms.nii.gz > ${nuisance_dir}/wm_qvec.1D
	3dmaskave -mask ${func_dir}/wm_mask_fs.nii.gz -quiet ${func_dir}/${rest}_gms.nii.gz > ${nuisance_dir}/wm.1D
fi

## 6. Generate mat file (for use later)
echo "Calculating the percent change from the mean ... [FSL: fslmaths]"
fslmaths ${tmprest} -Tmean ${func_dir}/${rest}_pp_mean.nii.gz
fslmaths ${tmprest} -sub ${func_dir}/${rest}_pp_mean.nii.gz -mas ${func_dir}/${rest}_pp_mask.nii.gz -div ${func_dir}/${rest}_pp_mean.nii.gz -mul 100 ${nuisance_dir}/tmp_pchange.nii.gz
nt=`fslnvols ${func_dir}/${rest}_gms.nii.gz` ; echo "There are ${nt} volumes ..."

## 7. Center 1D file (global/csf/wm)
echo "Mean centering the global/wm/csf time series ... [BASH]"
#Be careful the scientific notation of the numbers.
#global
SumVal=`1dsum ${nuisance_dir}/global.1D`
MeanVal=`awk -v a="$SumVal" -v b="$nt" 'BEGIN{print (a / b)}'`
1deval -a ${nuisance_dir}/global.1D -expr "a-$MeanVal" > ${nuisance_dir}/tmp_global.1D
if [ "${svd}" = "true" ]
then    
    #wm
    SumVal=`1dsum ${nuisance_dir}/wm_qvec.1D`
    MeanVal=`awk -v a="$SumVal" -v b="$nt" 'BEGIN{print (a / b)}'` 
    1deval -a ${nuisance_dir}/wm_qvec.1D -expr "a-$MeanVal" > ${nuisance_dir}/tmp_wm.1D
    #csf
    SumVal=`1dsum ${nuisance_dir}/csf_qvec.1D`
    MeanVal=`awk -v a="$SumVal" -v b="$nt" 'BEGIN{print (a / b)}'` 
    1deval -a ${nuisance_dir}/csf_qvec.1D -expr "a-$MeanVal" > ${nuisance_dir}/tmp_csf.1D
else
    #wm
    SumVal=`1dsum ${nuisance_dir}/wm.1D`
    MeanVal=`awk -v a="$SumVal" -v b="$nt" 'BEGIN{print (a / b)}'`
    1deval -a ${nuisance_dir}/wm.1D -expr "a-$MeanVal" > ${nuisance_dir}/tmp_wm.1D
    #csf
    SumVal=`1dsum ${nuisance_dir}/csf.1D`
    MeanVal=`awk -v a="$SumVal" -v b="$nt" 'BEGIN{print (a / b)}'`
    1deval -a ${nuisance_dir}/csf.1D -expr "a-$MeanVal" > ${nuisance_dir}/tmp_csf.1D
fi

## 8. Without removal of global signal
echo "Fit the data to two physiological nuisances: csf/wm noises ... [AFNI: 3dDeconvolve]"
    rm -f ${func_dir}/${rest}_psc_res.nii.gz
    3dDeconvolve \
    -input ${nuisance_dir}/tmp_pchange.nii.gz \
    -mask ${func_dir}/${rest}_pp_mask.nii.gz \
    -num_stimts 2 \
    -polort -1 \
    -stim_file 1 ${nuisance_dir}/tmp_wm.1D -stim_label 1 wm \
    -stim_file 2 ${nuisance_dir}/tmp_csf.1D -stim_label 2 csf \
    -tout -fout \
    -quiet \
    -errts ${func_dir}/${rest}_psc_res.nii.gz \
    -bucket ${nuisance_dir}/tmp_Fim_mcf.nii.gz

## 9. Removal of global signal    
echo "Fit the data to three physiological nuisances: global/csf/wm noises ... [AFNI: 3dDeconvolve]"
    rm -f ${func_dir}/${rest}_psc_res-gs.nii.gz
    3dDeconvolve \
    -input ${nuisance_dir}/tmp_pchange.nii.gz \
    -mask ${func_dir}/${rest}_pp_mask.nii.gz \
    -num_stimts 3 \
    -polort -1 \
    -stim_file 1 ${nuisance_dir}/tmp_global.1D -stim_label 1 global \
    -stim_file 2 ${nuisance_dir}/tmp_wm.1D -stim_label 2 wm \
    -stim_file 3 ${nuisance_dir}/tmp_csf.1D -stim_label 3 csf \
    -tout -fout \
    -quiet \
    -errts ${func_dir}/${rest}_psc_res-gs.nii.gz \
    -bucket ${nuisance_dir}/tmp_Fim_mcf-gs.nii.gz

## 10. Cleaning   
rm -rf ${nuisance_dir}/tmp*

## END: Back to non-PSC data
FC_dir=${func_dir}
if [ -f ${FC_dir}/${rest}_res.nii.gz ]
then
    rm -v ${FC_dir}/${rest}_res.nii.gz
fi
3dcalc -a ${FC_dir}/${rest}_psc_res.nii.gz -b ${func_dir}/${rest}_pp_mean.nii.gz -expr '(a*b)/100+b' -prefix ${FC_dir}/${rest}_res.nii.gz

gsFC_dir=${func_dir}/gs-removal ; mkdir -p ${gsFC_dir}
mv ${func_dir}/${rest}_psc_res-gs.nii.gz ${gsFC_dir}/${rest}_psc_res-gs.nii.gz
if [ -f ${gsFC_dir}/${rest}_res-gs.nii.gz ]
then
    rm -v ${gsFC_dir}/${rest}_res-gs.nii.gz
fi
3dcalc -a ${gsFC_dir}/${rest}_psc_res-gs.nii.gz -b ${func_dir}/${rest}_pp_mean.nii.gz -expr '(a*b)/100+b' -prefix ${gsFC_dir}/${rest}_res-gs.nii.gz
