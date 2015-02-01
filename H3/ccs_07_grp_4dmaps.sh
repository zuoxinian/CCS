#!/usr/bin/env bash

##########################################################################################################################
## CCS SCRIPT TO generagte (i.e., merge all individual maps) 4D files for second-level group analysis
##
## This script can be run on its own, by filling in the appropriate parameters
## Alternatively this script gets called from batch_process.sh, where you can use it to run N sites, one after the other.
##
## Written by R-fMRI master: Xi-Nian Zuo at IPCAS.
##########################################################################################################################


## analysisdirectory
dir=$1
## full/path/to/subject_list.txt containing subjects you want to run
subject_list=$2
## group analysis directory
grpdir=$3
## name of functional directory
func_dir_name=$4
## type of R-fMRI measure (if RSFC, then point to ${grpdir}/seeds_list.txt)
rfmri_index=$5
## prefix name for the group
prefix=$6

if [ $# -lt 6 ];
then
        echo -e "\033[47;35m Usage: $0 analysis_dir subject_list group_dir func_dir_name rfmri_index prefix \033[0m"
        exit
fi

## Get subjects to run
subjects=$( cat ${subject_list} )

mkdir -p ${grpdir}/${rfmri_index} 
cd ${grpdir}/${rfmri_index}
rm -f subjects_lackmaps_${prefix}.list

## A. SUBJECT LOOP
for subject in $subjects
do

## directory setup
func_dir=${dir}/${subject}/${func_dir_name}
func_reg_dir=${func_dir}/reg

echo -----------------------------
echo processing subject ${subject}
echo -----------------------------

echo Warpping ${rfmri_index} maps to ${standard_template} space
for metric in `cat ${grpdir}/${rfmri_index}/metrics.list` # you must create the metrics.list in grpdir before run this script!!
do
	if [[ -f ${func_dir}/${rfmri_index}/fnirt_${metric}_Zmap.nii.gz ]]
        then
		ln -s ${func_dir}/${rfmri_index}/fnirt_${metric}_Zmap.nii.gz ${subject}_${metric}.nii.gz
	else
                echo ${subject} >> subjects_lackmaps_${prefix}.list
	fi
done
## END SUBJECT LOOP
done

## With the alpha-order of subjects' names.
for metric in `cat ${grpdir}/${rfmri_index}/metrics.list`
do
	echo Merging all individual ${rfmri_index} maps to a 4D file
	fslmerge -t ${prefix}_${metric}_4D.nii.gz *_${metric}.nii.gz
	rm -rv *_${metric}.nii.gz
done
