#!/usr/bin/env bash

##########################################################################################################################
## CCS SCRIPT TO CALCULATE AMPLITUDE MEASURES OF THE LOW FREQUENCY OSCILLATIONS IN THE BOLD SIGNAL
##
## This script can be run on its own, by filling in the appropriate parameters
##
## Written by Xi-Nian Zuo, Maarten Mennes & Michael Milham
## for more information see www.nitrc.org/projects/fcon_1000
##
## Updated by Xi-Nian Zuo, Aug 14, 2011 at IPCAS (zuoxn@psych.ac.cn). 
##########################################################################################################################

## analysisdirectory
dir=$1
## full/path/to/subject_list.txt containing subjects you want to run
subject_list=$2
## name of resting-state scan (no extenstion)
rest=$3
## TR
TR=$4
## name of anatomical directory
anat_dir_name=$5
## name of functional directory
func_dir_name=$6
## if refine anat registration
do_refine_reg=$7
## standard template which final functional data registered to
standard_template=$8
## standard surface 
fsaverage=$9
## name of reg dir
reg_dir_name=${10}

## set your desired spatial smoothing FWHM - default is 6mm (acquisition voxel size is 3x3x3mm)
FWHM=6 ; sigma=$( echo "scale=10;${FWHM}/2.3548" | bc )
## frequency band setting: default LP (i.e., low frequency) = 0.01 ; default HP (i.e., high frequency) = 0.1
LP=0.01 ; HP=0.1 ; LP_slow4=0.027 ; HP_slow4=0.073

SUBJECTS_DIR=${dir} #Freesurfer setup

if [ $# -lt 9 ];
then
        echo -e "\033[47;35m Usage: $0 analysis_dir subject_list rest_name TR anat_dir_name func_dir_name do_refine_reg standard_template fsaverage \033[0m"
        exit
fi

echo ---------------------------------------
echo !!!! CALCULATING ALFF AND fALFF !!!!
echo ---------------------------------------

if [ $# -lt 10 ];
then
        reg_dir_name=reg
fi

## Get subjects to run
subjects=$( cat ${subject_list} )
## A. SUBJECT LOOP
for subject in $subjects
do

## directory setup
anat_dir=${dir}/${subject}/${anat_dir_name}
func_dir=${dir}/${subject}/${func_dir_name}
anat_reg_dir=${anat_dir}/${reg_dir_name}
func_reg_dir=${func_dir}/reg
ALFF_dir=${func_dir}/ALFF

echo --------------------------
echo running subject ${subject}
echo --------------------------

mkdir -p ${ALFF_dir} ; cd ${ALFF_dir}

## CALCULATING ALFF AND fALFF
if [ ! -f ALFF_Z.nii.gz ]
then
	## 1. primary calculations
	n_vols=`fslnvols ${rest}_pp_nofilt_sm${FWHM}.nii.gz` ; echo "there are ${n_vols} vols"
	## decide whether n_vols is odd or even
	MOD=`expr ${n_vols} % 2` ; echo "Odd (1) or Even (0): ${MOD}"
	## if odd, remove the first volume
	N=$(echo "scale=0; ${n_vols}/2"|bc) ; N=$(echo "2*${N}"|bc)  ; echo ${N}
	echo "Deleting the first volume from bold data due to a bug in fslpspec"
	if [ ${MOD} -eq 1 ]
	then
    		fslroi ${rest}_pp_nofilt_sm${FWHM}.nii.gz prealff_func_data.nii.gz 1 ${N}
	fi
	if [ ${MOD} -eq 0 ]
	then
    		cp ${rest}_pp_nofilt_sm${FWHM}.nii.gz prealff_func_data.nii.gz
	fi
	## 2. Computing power spectrum
	echo "Computing power spectrum"
	fslpspec prealff_func_data.nii.gz prealff_func_data_ps.nii.gz
	fslmaths prealff_func_data_ps.nii.gz -div ${N} -div ${N} prealff_func_data_ps.nii.gz #added by Xi-Nian, Dec 23, 2011.
	## copy power spectrum to keep it for later (i.e. it does not get deleted in the clean up at the end of the script)
	cp prealff_func_data_ps.nii.gz power_spectrum_distribution.nii.gz
	echo "Computing square root of power spectrum"
	fslmaths prealff_func_data_ps.nii.gz -sqrt prealff_func_data_ps_sqrt.nii.gz
	## 3. Calculate ALFF
	echo "Extracting power spectrum at the slow frequency band"
	## calculate the low frequency point
	n_lp=$(echo "scale=10; ${LP}*${N}*${TR}"|bc)
	n1=$(echo "${n_lp}-1"|bc|xargs printf "%1.0f") ; 
	echo "${LP} Hz is around the ${n1} frequency point."
	#slow4
	n_lp4=$(echo "scale=10; ${LP_slow4}*${N}*${TR}"|bc)
	n1_s4=$(echo "${n_lp4}-1"|bc|xargs printf "%1.0f") 
	echo "${LP_slow4} Hz is around the ${n1_s4} frequency point."
	## calculate the high frequency point
	n_hp=$(echo "scale=10; ${HP}*${N}*${TR}"|bc)
	n2=$(echo "${n_hp}-${n_lp}+1"|bc|xargs printf "%1.0f") ; 
	echo "There are about ${n2} frequency points before ${HP} Hz."
	#slow4
	n_hp4=$(echo "scale=10; ${HP_slow4}*${N}*${TR}"|bc)
	n2_s4=$(echo "${n_hp4}-${n_lp4}+1"|bc|xargs printf "%1.0f") ; 
	echo "There are about ${n2_s4} frequency points before ${HP_slow4} Hz."
	## cut the low frequency data from the the whole frequency band
	fslroi prealff_func_data_ps_sqrt.nii.gz prealff_func_ps_slow.nii.gz ${n1} ${n2}
	fslroi prealff_func_data_ps_sqrt.nii.gz prealff_func_ps_slow4.nii.gz ${n1_s4} ${n2_s4}
	## calculate ALFF as the sum of the amplitudes in the low frequency band
	echo "Computing amplitude of the low frequency fluctuations (ALFF)"
	fslmaths prealff_func_ps_slow.nii.gz -Tmean -mul ${n2} prealff_func_ps_alff4slow.nii.gz
	cp prealff_func_ps_alff4slow.nii.gz ALFF.nii.gz
	#slow4
	fslmaths prealff_func_ps_slow4.nii.gz -Tmean -mul ${n2_s4} prealff_func_ps_alff4slow4.nii.gz
	cp prealff_func_ps_alff4slow4.nii.gz ALFF_slow4.nii.gz
	## 4. Calculate fALFF
	echo "Computing amplitude of total frequency"
	fslmaths prealff_func_data_ps_sqrt.nii.gz -Tmean -mul ${N} -div 2 prealff_func_ps_sum.nii.gz
	## calculate fALFF as ALFF/amplitude of total frequency
	echo "Computing fALFF"
	fslmaths prealff_func_ps_alff4slow.nii.gz -div prealff_func_ps_sum.nii.gz fALFF.nii.gz
	fslmaths prealff_func_ps_alff4slow4.nii.gz -div prealff_func_ps_sum.nii.gz fALFF_slow4.nii.gz
	## 5. Z-normalisation across whole brain
	echo "Normalizing ALFF/fALFF to Z-score across full brain"
	for metric in ALFF fALFF ALFF_slow4 fALFF_slow4
	do
		echo ${metric}
		fslstats ${metric}.nii.gz -k ${func_dir}/${rest}_pp_mask.nii.gz -m > mean_${metric}.txt ; 
		mean=$( cat mean_${metric}.txt )
		fslstats ${metric}.nii.gz -k ${func_dir}/${rest}_pp_mask.nii.gz -s > std_${metric}.txt ; 
		std=$( cat std_${metric}.txt )
		echo $mean $std 
		fslmaths ${metric}.nii.gz -sub ${mean} -div ${std} -mas ${func_dir}/${rest}_pp_mask.nii.gz ${metric}_Z.nii.gz
		## 6. Register Z-transformed ALFF and fALFF maps to standard space
		if [ "${do_refine_reg}" = "true" ]; 
		then
    			echo Registering Z-transformed ${metric} to study-specific template
    			applywarp --ref=${standard_template} --in=${ALFF_dir}/${metric}_Z.nii.gz --out=${ALFF_dir}/fnirt_${metric}_Zmap.nii.gz --warp=${anat_reg_dir}/highres2standard_ref_warp --premat=${func_reg_dir}/example_func2highres.mat
		else
    			echo Registering Z-transformed ${netric} to study-specific template
    			applywarp --ref=${standard_template} --in=${ALFF_dir}/${metric}_Z.nii.gz --out=${ALFF_dir}/fnirt_${metric}_Zmap.nii.gz --warp=${anat_reg_dir}/highres2standard_warp --premat=${func_reg_dir}/example_func2highres.mat
		fi
	done
	## 7. Clean up
	echo "Clean up temporary files"
	rm -rf prealff_*.nii.gz
fi
## END OF SUBJECT LOOP
done

cd ${cwd}

