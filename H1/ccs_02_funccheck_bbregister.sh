#!/usr/bin/env bash

##########################################################################################################################
## CCS SCRIPT TO DO QUALITY ASSURANCE OF ANATOMICAL SURFACE PROCESSING
##
## !!!!!*****ALWAYS CHECK YOUR REGISTRATION*****!!!!!
##
## Thanks go to Thomas Yeo for sharing his excellant codes.
##
## R-fMRI master: Xi-Nian Zuo. Dec. 07, 2011, Institute of Psychology, CAS.
##
## Email: zuoxn@psych.ac.cn.
##
## Last Modified: 08/01/2014.
##########################################################################################################################

## full/path/to/site
dir=$1
## full/path/to/site/subject_list
subject_list=$2
## name of functional directory
func_dir_name=$3
## standard template
clean_bool=$4
## set parameters
SUBJECTS_DIR=${dir}
edgecolor=red; edgethickness=1;
min_val=500; max_val=1300;
opacity=1; width=500; height=500;
if [ $# -lt 4 ]; 
then
    	echo -e "\033[47;35m Usage: $0 subjects_dir subjects_list func_dir_name clean_bool \033[0m"
	exit
fi
if [ -e ~/.freeview ]; then rm ~/.freeview ; fi
## Start scripts
for subject in `cat ${subject_list}`
do
  if [ ! -f ${dir}/${subject}/${func_dir_name}/reg/vcheck/summary.png ]
  then
	echo "Processing ${subject} ..."
  	func_dir=${dir}/${subject}/${func_dir_name}
	func_reg_dir=${func_dir}/reg
  	output_dir=${func_reg_dir}/vcheck
	mkdir -p $output_dir
	anat_volume=${SUBJECTS_DIR}/${subject}/mri/norm.mgz
	mean_anat_fmri=${func_reg_dir}/mean_func2norm.nii.gz
	mean_fmri=${func_dir}/mean_func_mc.nii.gz
	if [ ! -e ${mean_fmri} ]; then
		echo Please generate the mean functional image.
		exit
	fi
	if [ ! -e ${mean_anat_fmri} ]; then
		if [ -e ${func_reg_dir}/bbregister.dof6.dat ]; then
			mri_vol2vol --mov ${func_dir}/mean_func_mc.nii.gz --targ ${anat_volume} --reg ${func_reg_dir}/bbregister.dof6.dat --no-save-reg --o ${mean_anat_fmri} 
		else
			echo Please check if you run bbregister!
		fi
	else
		echo Please check if you run bbregister or ${mean_anat_fmri} already exists!
	fi
	# Draw with freeview and save coronal slices
	if [ ! -e $output_dir/coronal.png ]; 
	then
    		for coronal in 64 96 128 148 168
        	do
			freeview --viewsize $width $height -viewport coronal -slice 1 1 $coronal -ss ${output_dir}/coronal.$coronal.png -v ${mean_anat_fmri}:opacity=${opacity}:grayscale=${min_val},${max_val} -f ${SUBJECTS_DIR}/${subject}/surf/lh.white:edgecolor=$edgecolor:edgethickness=${edgethickness} -f ${SUBJECTS_DIR}/${subject}/surf/rh.white:edgecolor=$edgecolor:edgethickness=${edgethickness}
            		convert -flop ${output_dir}/coronal.$coronal.png ${output_dir}/coronal.$coronal.png # flip horizontal axis so as to be in neurological coordinates
    		done
		pngappend ${output_dir}/coronal.64.png + ${output_dir}/coronal.96.png + ${output_dir}/coronal.128.png + ${output_dir}/coronal.148.png + ${output_dir}/coronal.168.png ${output_dir}/coronal.png
    		if [ ! -f ${output_dir}/coronal.png ]
		then
			convert ${output_dir}/coronal.64.png ${output_dir}/coronal.96.png ${output_dir}/coronal.128.png ${output_dir}/coronal.148.png ${output_dir}/coronal.168.png +append ${output_dir}/coronal.png
		fi
	fi
	# Draw with freeview and save axial slices
        if [ ! -e $output_dir/axial.png ]; 
	then
        	for axial in 55 70 85 100 115 
        	do      
			freeview --viewsize $width $height -viewport axial -slice 1 $axial 1 -ss ${output_dir}/axial.$axial.png -v ${mean_anat_fmri}:opacity=${opacity}:grayscale=${min_val},${max_val} -f ${SUBJECTS_DIR}/${subject}/surf/lh.white:edgecolor=$edgecolor:edgethickness=${edgethickness} -f ${SUBJECTS_DIR}/${subject}/surf/rh.white:edgecolor=$edgecolor:edgethickness=${edgethickness}
        		convert -flop ${output_dir}/axial.$axial.png ${output_dir}/axial.$axial.png # flip horizontal axis so as to be in neurological coordinates
		done
		pngappend ${output_dir}/axial.55.png + ${output_dir}/axial.70.png + ${output_dir}/axial.85.png + ${output_dir}/axial.100.png + ${output_dir}/axial.115.png ${output_dir}/axial.png
		if [ ! -f ${output_dir}/axial.png ]
		then
			convert ${output_dir}/axial.55.png ${output_dir}/axial.70.png ${output_dir}/axial.85.png ${output_dir}/axial.100.png ${output_dir}/axial.115.png +append ${output_dir}/axial.png
		fi
	fi
	# Draw with freeview and save sagittal slices
        if [ ! -e $output_dir/sagittal.png ]; 
	then
        	for sagittal in 78 98 118 138 158
        	do
			freeview --viewsize $width $height -viewport sagittal -slice $sagittal 1 1 -ss ${output_dir}/sagittal.$sagittal.png -v ${mean_anat_fmri}:opacity=${opacity}:grayscale=${min_val},${max_val} -f ${SUBJECTS_DIR}/${subject}/surf/lh.white:edgecolor=$edgecolor:edgethickness=${edgethickness} -f ${SUBJECTS_DIR}/${subject}/surf/rh.white:edgecolor=$edgecolor:edgethickness=${edgethickness}
		done
		pngappend ${output_dir}/sagittal.78.png + ${output_dir}/sagittal.98.png + ${output_dir}/sagittal.118.png + ${output_dir}/sagittal.138.png + ${output_dir}/sagittal.158.png ${output_dir}/sagittal.png
		if [ ! -f ${output_dir}/sagittal.png ]
		then
			convert ${output_dir}/sagittal.78.png ${output_dir}/sagittal.98.png ${output_dir}/sagittal.118.png ${output_dir}/sagittal.138.png ${output_dir}/sagittal.158.png +append ${output_dir}/sagittal.png
		fi
	fi
	# remove remaining files
	if [ ${clean_bool} = "true" ];
	then
    		if [ -e ${output_dir}/coronal.png ];
		then
        		rm ${output_dir}/coronal.*.png
    		fi

    		if [ -e ${output_dir}/axial.png ];
		then
        		rm ${output_dir}/axial.*.png
    		fi

    		if [ -e ${output_dir}/sagittal.png ]; 
		then
        		rm ${output_dir}/sagittal.*.png
    		fi
	fi
	# single summary
	pngappend ${output_dir}/coronal.png - ${output_dir}/axial.png - ${output_dir}/sagittal.png ${output_dir}/summary.png
	if [ ! -f ${output_dir}/summary.png ]
	then
		convert ${output_dir}/coronal.png ${output_dir}/axial.png ${output_dir}/sagittal.png -append ${output_dir}/summary.png
	fi
	title=${subject}.ccs.qcp.func.reg.bbregister
	convert -font helvetica -fill white -pointsize 20 -draw "text 10,20 '$title'" ${output_dir}/summary.png ${output_dir}/summary.png
 else
 	echo "BBR check has beeb run for ${subject}!"
 fi
done
