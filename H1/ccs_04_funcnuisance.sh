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


## 1. make nuisance directory
mkdir -p ${nuisance_dir}; cd ${nuisance_dir}
## 2.1 generate the temporal derivates of motion
1d_tool.py -infile ${func_dir}/${rest}_mc.1D -derivative -write ${func_dir}/${rest}_mcdt.1D

## 2.2 Seperate motion parameters into seperate files
echo "Splitting up ${subject} motion parameters"
awk '{print $1}' ${func_dir}/${rest}_mc.1D > ${nuisance_dir}/mc1.1D
awk '{print $2}' ${func_dir}/${rest}_mc.1D > ${nuisance_dir}/mc2.1D
awk '{print $3}' ${func_dir}/${rest}_mc.1D > ${nuisance_dir}/mc3.1D
awk '{print $4}' ${func_dir}/${rest}_mc.1D > ${nuisance_dir}/mc4.1D
awk '{print $5}' ${func_dir}/${rest}_mc.1D > ${nuisance_dir}/mc5.1D
awk '{print $6}' ${func_dir}/${rest}_mc.1D > ${nuisance_dir}/mc6.1D
awk '{print $1}' ${func_dir}/${rest}_mcdt.1D > ${nuisance_dir}/mcdt1.1D
awk '{print $2}' ${func_dir}/${rest}_mcdt.1D > ${nuisance_dir}/mcdt2.1D
awk '{print $3}' ${func_dir}/${rest}_mcdt.1D > ${nuisance_dir}/mcdt3.1D
awk '{print $4}' ${func_dir}/${rest}_mcdt.1D > ${nuisance_dir}/mcdt4.1D
awk '{print $5}' ${func_dir}/${rest}_mcdt.1D > ${nuisance_dir}/mcdt5.1D
awk '{print $6}' ${func_dir}/${rest}_mcdt.1D > ${nuisance_dir}/mcdt6.1D
echo "Preparing 1D files for Friston-24 motion correction"
for ((k=1 ; k <= 6 ; k++))
do
	# calculate the squared MC files
	1deval -a ${nuisance_dir}/mc${k}.1D -expr 'a*a' > ${nuisance_dir}/mcsqr${k}.1D
	# calculate the AR and its squared MC files
	1deval -a ${nuisance_dir}/mc${k}.1D -b ${nuisance_dir}/mcdt${k}.1D -expr 'a-b' > ${nuisance_dir}/mcar${k}.1D
	1deval -a ${nuisance_dir}/mcar${k}.1D -expr 'a*a' > ${nuisance_dir}/mcarsqr${k}.1D
done

# Extract signal for global, csf, and wm
## 3. Global
echo "Extracting global signal for ${subject}"
3dmaskave -mask ${func_segment_dir}/global_mask.nii.gz -quiet ${func_dir}/${rest}_gms.nii.gz > ${nuisance_dir}/global.1D

## 4/5. csf and white matter
echo "Extracting signal from csf for ${subject}"
if [ -e ${func_dir}/csf_mask_fs.nii.gz ]
then
	3dmaskSVD -vnorm -mask ${func_dir}/csf_mask_fs.nii.gz -polort 0 ${func_dir}/${rest}_gms.nii.gz > ${nuisance_dir}/csf_qvec.1D
	3dmaskave -mask ${func_dir}/csf_mask_fs.nii.gz -quiet ${func_dir}/${rest}_gms.nii.gz > ${nuisance_dir}/csf.1D
fi
echo "Extracting signal from white matter for ${subject}"
if [ -e ${func_dir}/wm_mask_fs.nii.gz ]
then
	3dmaskSVD -vnorm -mask ${func_dir}/wm_mask_fs.nii.gz -polort 0 ${func_dir}/${rest}_gms.nii.gz > ${nuisance_dir}/wm_qvec.1D
	3dmaskave -mask ${func_dir}/wm_mask_fs.nii.gz -quiet ${func_dir}/${rest}_gms.nii.gz > ${nuisance_dir}/wm.1D
fi

## 6. Generate mat file (for use later)
echo "Calculating the percent change from the mean ... [FSL: fslmaths]"
fslmaths ${func_dir}/${rest}_gms.nii.gz -Tmean ${func_dir}/${rest}_pp_mean.nii.gz
fslmaths ${func_dir}/${rest}_gms.nii.gz -sub ${func_dir}/${rest}_pp_mean.nii.gz -mas ${func_dir}/${rest}_pp_mask.nii.gz -div ${func_dir}/${rest}_pp_mean.nii.gz -mul 100 ${nuisance_dir}/tmp_pchange.nii.gz
nt=`fslnvols ${func_dir}/${rest}_gms.nii.gz` ; echo "There are ${nt} volumes ..."
echo "Mean centering all the motion time series ... [BASH]"
for ((k=1 ; k <= 6 ; k++))
do
	##RAW
        # calculate the sum and then the mean of each motion parameter
	SumVal=`1dsum ${nuisance_dir}/mc$k.1D` ; #echo ${SumVal}
	MeanVal=`awk -v a="$SumVal" -v b="$nt" 'BEGIN{print (a / b)}'` ; #echo ${MeanVal}
        #write a tempory file for each mean subtracted time series
	1deval -a ${nuisance_dir}/mc$k.1D -expr "a-$MeanVal" > ${nuisance_dir}/tmp_mc$k.1D
	##SQR
	# calculate the sum and then the mean of each motion parameter
        SumVal=`1dsum ${nuisance_dir}/mcsqr$k.1D` ; #echo ${SumVal}
        MeanVal=`awk -v a="$SumVal" -v b="$nt" 'BEGIN{print (a / b)}'` ; #echo ${MeanVal}
        #write a tempory file for each mean subtracted time series
        1deval -a ${nuisance_dir}/mcsqr$k.1D -expr "a-$MeanVal" > ${nuisance_dir}/tmp_mcsqr$k.1D
	##AR(1)-RAW
	# calculate the sum and then the mean of each motion parameter
        SumVal=`1dsum ${nuisance_dir}/mcar$k.1D` ; #echo ${SumVal}
        MeanVal=`awk -v a="$SumVal" -v b="$nt" 'BEGIN{print (a / b)}'` ; #echo ${MeanVal}
        #write a tempory file for each mean subtracted time series
        1deval -a ${nuisance_dir}/mcar$k.1D -expr "a-$MeanVal" > ${nuisance_dir}/tmp_mcar$k.1D
        ##AR(1)-SQR
        # calculate the sum and then the mean of each motion parameter
        SumVal=`1dsum ${nuisance_dir}/mcarsqr$k.1D` ; #echo ${SumVal}
        MeanVal=`awk -v a="$SumVal" -v b="$nt" 'BEGIN{print (a / b)}'` ; #echo ${MeanVal}
        #write a tempory file for each mean subtracted time series
        1deval -a ${nuisance_dir}/mcarsqr$k.1D -expr "a-$MeanVal" > ${nuisance_dir}/tmp_mcarsqr$k.1D
done

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
## Without removal of global signal
echo "Fit the data to eight nuisances: the movement parameters, csf/wm noises ... [AFNI: 3dDeconvolve]"
    rm -f ${func_dir}/${rest}_psc_res.nii.gz
    3dDeconvolve \
    -input ${nuisance_dir}/tmp_pchange.nii.gz \
    -mask ${func_dir}/${rest}_pp_mask.nii.gz \
    -num_stimts 26 \
    -polort -1 \
    -stim_file 1 ${nuisance_dir}/tmp_mc1.1D -stim_label 1 mc1 \
    -stim_file 2 ${nuisance_dir}/tmp_mc2.1D -stim_label 2 mc2 \
    -stim_file 3 ${nuisance_dir}/tmp_mc3.1D -stim_label 3 mc3 \
    -stim_file 4 ${nuisance_dir}/tmp_mc4.1D -stim_label 4 mc4 \
    -stim_file 5 ${nuisance_dir}/tmp_mc5.1D -stim_label 5 mc5 \
    -stim_file 6 ${nuisance_dir}/tmp_mc6.1D -stim_label 6 mc6 \
    -stim_file 7 ${nuisance_dir}/tmp_mcar1.1D -stim_label 7 mcar1 \
    -stim_file 8 ${nuisance_dir}/tmp_mcar2.1D -stim_label 8 mcar2 \
    -stim_file 9 ${nuisance_dir}/tmp_mcar3.1D -stim_label 9 mcar3 \
    -stim_file 10 ${nuisance_dir}/tmp_mcar4.1D -stim_label 10 mcar4 \
    -stim_file 11 ${nuisance_dir}/tmp_mcar5.1D -stim_label 11 mcar5 \
    -stim_file 12 ${nuisance_dir}/tmp_mcar6.1D -stim_label 12 mcar6 \
    -stim_file 13 ${nuisance_dir}/tmp_mcsqr1.1D -stim_label 13 mcsqr1 \
    -stim_file 14 ${nuisance_dir}/tmp_mcsqr2.1D -stim_label 14 mcsqr2 \
    -stim_file 15 ${nuisance_dir}/tmp_mcsqr3.1D -stim_label 15 mcsqr3 \
    -stim_file 16 ${nuisance_dir}/tmp_mcsqr4.1D -stim_label 16 mcsqr4 \
    -stim_file 17 ${nuisance_dir}/tmp_mcsqr5.1D -stim_label 17 mcsqr5 \
    -stim_file 18 ${nuisance_dir}/tmp_mcsqr6.1D -stim_label 18 mcsqr6 \
    -stim_file 19 ${nuisance_dir}/tmp_mcarsqr1.1D -stim_label 19 mcarsqr1 \
    -stim_file 20 ${nuisance_dir}/tmp_mcarsqr2.1D -stim_label 20 mcarsqr2 \
    -stim_file 21 ${nuisance_dir}/tmp_mcarsqr3.1D -stim_label 21 mcarsqr3 \
    -stim_file 22 ${nuisance_dir}/tmp_mcarsqr4.1D -stim_label 22 mcarsqr4 \
    -stim_file 23 ${nuisance_dir}/tmp_mcarsqr5.1D -stim_label 23 mcarsqr5 \
    -stim_file 24 ${nuisance_dir}/tmp_mcarsqr6.1D -stim_label 24 mcarsqr6 \
    -stim_file 25 ${nuisance_dir}/tmp_wm.1D -stim_label 25 wm \
    -stim_file 26 ${nuisance_dir}/tmp_csf.1D -stim_label 26 csf \
    -tout -fout \
    -quiet \
    -errts ${func_dir}/${rest}_psc_res.nii.gz \
    -bucket ${nuisance_dir}/tmp_Fim_mcf.nii.gz

## Removal of global signal    
echo "Fit the data to all nine nuisances: the movement parameters, global/csf/wm noises ... [AFNI: 3dDeconvolve]"
    rm -f ${func_dir}/${rest}_psc_res-gs.nii.gz
    3dDeconvolve \
    -input ${nuisance_dir}/tmp_pchange.nii.gz \
    -mask ${func_dir}/${rest}_pp_mask.nii.gz \
    -num_stimts 27 \
    -polort -1 \
    -stim_file 1 ${nuisance_dir}/tmp_mc1.1D -stim_label 1 mc1 \
    -stim_file 2 ${nuisance_dir}/tmp_mc2.1D -stim_label 2 mc2 \
    -stim_file 3 ${nuisance_dir}/tmp_mc3.1D -stim_label 3 mc3 \
    -stim_file 4 ${nuisance_dir}/tmp_mc4.1D -stim_label 4 mc4 \
    -stim_file 5 ${nuisance_dir}/tmp_mc5.1D -stim_label 5 mc5 \
    -stim_file 6 ${nuisance_dir}/tmp_mc6.1D -stim_label 6 mc6 \
    -stim_file 7 ${nuisance_dir}/tmp_mcar1.1D -stim_label 7 mcar1 \
    -stim_file 8 ${nuisance_dir}/tmp_mcar2.1D -stim_label 8 mcar2 \
    -stim_file 9 ${nuisance_dir}/tmp_mcar3.1D -stim_label 9 mcar3 \
    -stim_file 10 ${nuisance_dir}/tmp_mcar4.1D -stim_label 10 mcar4 \
    -stim_file 11 ${nuisance_dir}/tmp_mcar5.1D -stim_label 11 mcar5 \
    -stim_file 12 ${nuisance_dir}/tmp_mcar6.1D -stim_label 12 mcar6 \
    -stim_file 13 ${nuisance_dir}/tmp_mcsqr1.1D -stim_label 13 mcsqr1 \
    -stim_file 14 ${nuisance_dir}/tmp_mcsqr2.1D -stim_label 14 mcsqr2 \
    -stim_file 15 ${nuisance_dir}/tmp_mcsqr3.1D -stim_label 15 mcsqr3 \
    -stim_file 16 ${nuisance_dir}/tmp_mcsqr4.1D -stim_label 16 mcsqr4 \
    -stim_file 17 ${nuisance_dir}/tmp_mcsqr5.1D -stim_label 17 mcsqr5 \
    -stim_file 18 ${nuisance_dir}/tmp_mcsqr6.1D -stim_label 18 mcsqr6 \
    -stim_file 19 ${nuisance_dir}/tmp_mcarsqr1.1D -stim_label 19 mcarsqr1 \
    -stim_file 20 ${nuisance_dir}/tmp_mcarsqr2.1D -stim_label 20 mcarsqr2 \
    -stim_file 21 ${nuisance_dir}/tmp_mcarsqr3.1D -stim_label 21 mcarsqr3 \
    -stim_file 22 ${nuisance_dir}/tmp_mcarsqr4.1D -stim_label 22 mcarsqr4 \
    -stim_file 23 ${nuisance_dir}/tmp_mcarsqr5.1D -stim_label 23 mcarsqr5 \
    -stim_file 24 ${nuisance_dir}/tmp_mcarsqr6.1D -stim_label 24 mcarsqr6 \
    -stim_file 25 ${nuisance_dir}/tmp_global.1D -stim_label 25 global \
    -stim_file 26 ${nuisance_dir}/tmp_wm.1D -stim_label 26 wm \
    -stim_file 27 ${nuisance_dir}/tmp_csf.1D -stim_label 27 csf \
    -tout -fout \
    -quiet \
    -errts ${func_dir}/${rest}_psc_res-gs.nii.gz \
    -bucket ${nuisance_dir}/tmp_Fim_mcf-gs.nii.gz
## Cleaning   
rm -rf ${nuisance_dir}/tmp*

## 0. Back to non-PSC data
FC_dir=${func_dir}
gsFC_dir=${func_dir}/gs-removal
mkdir -p ${gsFC_dir}
3dcalc -a ${FC_dir}/${rest}_psc_res.nii.gz -b ${func_dir}/${rest}_pp_mean.nii.gz -expr '(a*b)/100+b' -prefix ${FC_dir}/${rest}_res.nii.gz
if [ ! -f ${gsFC_dir}/${rest}_psc_res-gs.nii.gz ]
then
	mv ${func_dir}/${rest}_psc_res-gs.nii.gz ${gsFC_dir}/${rest}_psc_res-gs.nii.gz
        3dcalc -a ${gsFC_dir}/${rest}_psc_res-gs.nii.gz -b ${func_dir}/${rest}_pp_mean.nii.gz -expr '(a*b)/100+b' -prefix ${gsFC_dir}/${rest}_res-gs.nii.gz
fi 
