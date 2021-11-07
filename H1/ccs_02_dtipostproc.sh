#!/usr/bin/env bash

##########################################################################################################################
## CCS SCRIPT TO PREPROCESS THE DTI SCAN (INTEGRATE AFNI, FS AND FSL)
##
## R-fMRI master: Xi-Nian Zuo. Dec. 20, 2014.
##
## Last Modified: Dec., 16, 2015.
## Email: zuoxn@psych.ac.cn or zuoxinian@gmail.com.
##########################################################################################################################

## subject
subject=$1
## analysisdirectory
dir=$2
## name of the diffution weighted scan
dti=$3
## name of the dti directory
dti_dir_name=$4
## number of seeds
num_seeds=$5
## location of dti tools
dtitool_dir=$6

## directory setup
dti_dir=${dir}/${subject}/${dti_dir_name}

if [ $# -lt 6 ];
then
        echo -e "\033[47;35m Usage: $0 subject analysis_dir dti_name dti_dir_name num_seeds dti_tools \033[0m "
        exit
fi

echo ---------------------------------------
echo !!!! POSTPROCESSING DIFFUSION SCAN !!!!
echo ---------------------------------------

echo "Fitting DTI parameters for ${subject}"

#Fitting Diffusion Tensor: FSL-FDT
#if [ ! -f ${dti_dir}/fdt/dtifit_FA.nii.gz ]
#then
mkdir -p ${dti_dir}/fdt ; cd ${dti_dir}/fdt
dtifit --data=${dti_dir}/data_eddy.nii.gz --out=dtifit --mask=${dti_dir}/b0_brain_mask.nii.gz --bvecs=${dti_dir}/${dti}.bvec --bvals=${dti_dir}/${dti}.bval
#fi

#Fitting Diffusion Tensor: DTK
#if [ ! -f ${dti_dir}/dtk/dtifit_fa.nii.gz ]
#then
mkdir -p ${dti_dir}/dtk ; cd ${dti_dir}/dtk
3dTcat -output tmpdata.nii.gz ${dti_dir}/b0.nii.gz ${dti_dir}/data_eddy.nii.gz
cat ${dti_dir}/${dti}.bvec ${dti_dir}/${dti}.bval > tmpgrad.txt
rm -v gradient.txt ; 1dtranspose tmpgrad.txt gradient.txt
echo "0 0 0 0" > gradient.b0
cat gradient.b0 gradient.txt > gradient.gm
${dtitool_dir}/dtk/dti_recon tmpdata.nii.gz dtifit -gm gradient.gm -b0 1 -it nii.gz -ot nii.gz
rm -v tmp*
#fi

#Fitting Diffusion Tensor: FATCAT
cd ${dti_dir} ; numB0=0; numDiff=0
n_vols=`fslnvols ${dti}.nii.gz`
for b0ID in `cat ${dti}.bval`
do
    if [ ${numDiff} -eq 0 ]
    then
	b0val=${b0ID}
    fi
    if [ "$b0ID" -eq "$b0ID" ] 2>/dev/null;
    then
	let numDiff=numDiff+1
    fi
done
mkdir -p ${dti_dir}/fatcat ; cd ${dti_dir}/fatcat ; 
mkdir -p pool ; rm -v order_nob0.1D
if [[ ${n_vols} == ${numDiff} ]]
then
    numDiff=0 ; idDiff=0
    for b0ID in `cat ${dti_dir}/${dti}.bval`
    do
	if [ "$b0ID" -eq "$b0ID" ] 2>/dev/null;#possibility of a bug
	then
	    let numDiff=numDiff+1
            if [[ ${b0ID} != ${b0val} ]]
            then
		echo "NoneB0 image is detected."
		let idDiff=idDiff+1
		if [ ${idDiff} -eq 1 ]
		then
		    echo ${idDiff}
		    cut -d " " -f${numDiff} ${dti_dir}/${dti}.bvec > pool/${dti}_nob0.1D
		fi
		if [ ${idDiff} -gt 1 ]
		then
		    cut -d " " -f${numDiff} ${dti_dir}/${dti}.bvec > tmp_vec.1D
		    if [ -f ${dti}_nob0.1D ]
		    then
			rm -v ${dti}_nob0.1D
		    fi
		    1dcat pool/${dti}_nob0.1D tmp_vec.1D > ${dti}_nob0.1D
		    mv ${dti}_nob0.1D pool/${dti}_nob0.1D
		fi
		let num0Diff=numDiff-1;	echo ${num0Diff} >> order_nob0.1D
            fi
	fi
    done
    1dtranspose pool/${dti}_nob0.1D > ${dti}_nob0.bvec
    3dTcat -prefix tmp_eddy_nob0.nii.gz ${dti_dir}/data_eddy.nii.gz'[1dcat order_nob0.1D]'
    fslmerge -t data_eddy_oneb0.nii.gz ${dti_dir}/b0.nii.gz tmp_eddy_nob0.nii.gz
    rm -rv tmp_diff.nii.gz tmp_vec.1D tmp_eddy_nob0.nii.gz pool
    3dDWItoDT -prefix dtifit -mask ${dti_dir}/b0_brain_mask.nii.gz -eigs -nonlinear -reweight -sep_dsets ${dti}_nob0.bvec data_eddy_oneb0.nii.gz
else
    echo "Check the number of diffusion imaging!" > fatcat.error
fi

#Tracting fibers: DTK
#if [ ! -f ${dti_dir}/dtk/tracks_16seeds.trk ]
#then
cd ${dti_dir}/dtk
${dtitool_dir}/dtk/dti_tracker dtifit tracks_${num_seeds}seeds.trk -it nii.gz -at 45 -rseed ${num_seeds} -m ${dti_dir}/b0_brain_mask.nii.gz -m2 dtifit_fa.nii.gz 0.1
#fi
