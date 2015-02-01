#!/usr/bin/env bash

##########################################################################################################################
## CCS SCRIPT TO DO QUALITY ASSURANCE OF ANATOMICAL SURFACE PROCESSING
##
## !!!!!*****ALWAYS CHECK YOUR SURFACES*****!!!!!
##
## Thanks go to Thomas Yeo for sharing his excellant codes.
## Modified by R-fMRI master: Xi-Nian Zuo. Dec. 07, 2011, Institute of Psychology, CAS.
## Email: zuoxn@psych.ac.cn.
##
## Last Modified: 08/01/2014.
##########################################################################################################################

## full/path/to/site
dir=$1
## full/path/to/site/subject_list
subject_list=$2
## name of anatomical directory
anat_dir_name=$3


## standard template
clean_bool=$4
## set parameters
SUBJECTS_DIR=${dir}
edgecolorwm=red;
edgecolorpial=yellow;
edgethickness=1;
min_val=0; max_val=137;
opacity=1; width=500; height=500;


if [ $# -lt 4 ]; 
then
    	echo -e "\033[47;35m Usage: $0 subjects_dir subjects_list anat_dir_name clean_bool \033[0m"
	exit
fi
if [ -e ~/.freeview ]; then rm ~/.freeview; fi
## Start scripts
for subject in `cat ${subject_list}`
do
  	echo "Processing ${subject} ..."
  	anat_dir=${dir}/${subject}/${anat_dir_name}
  	output_dir=${anat_dir}/vcheck
	mkdir -p $output_dir
	anat_volume=${SUBJECTS_DIR}/${subject}/mri/brainmask.mgz
	aseg_volume=${SUBJECTS_DIR}/${subject}/mri/aparc.a2009s+aseg.mgz
	if [ -f ${SUBJECTS_DIR}/${subject}/surf/lh.pial ]
	then
	# Draw with freeview and save coronal.segment.slices
	if [ ! -e $output_dir/coronal.segment.png ]; 
	then
    		for cid in 64 96 128 148 168
        	do
			freeview --viewsize $width $height -viewport coronal -slice 1 1 $cid -ss $output_dir/coronal.segment.$cid.png -v ${anat_volume}:opacity=${opacity}:grayscale=${min_val},${max_val} ${aseg_volume}:colormap=lut:opacity=0.85 
            		convert -flop ${output_dir}/coronal.segment.$cid.png ${output_dir}/coronal.segment.$cid.png # flip horizontal axis so as to be in neurological coordinates
    		done
		pngappend ${output_dir}/coronal.segment.64.png + ${output_dir}/coronal.segment.96.png + ${output_dir}/coronal.segment.128.png + ${output_dir}/coronal.segment.148.png + ${output_dir}/coronal.segment.168.png ${output_dir}/coronal.segment.png
		if [ ! -e ${output_dir}/coronal.segment.png ]
		then
			convert ${output_dir}/coronal.segment.64.png ${output_dir}/coronal.segment.96.png ${output_dir}/coronal.segment.128.png ${output_dir}/coronal.segment.148.png ${output_dir}/coronal.segment.168.png +append ${output_dir}/coronal.segment.png
		fi
	fi
	# Draw with freeview and save axial.segment.slices
        if [ ! -e $output_dir/axial.segment.png ]; 
	then
        	for aid in 55 70 85 100 115 
        	do      
                	freeview --viewsize $width $height -viewport axial -slice 1 $aid 1 -ss ${output_dir}/axial.segment.$aid.png -v ${anat_volume}:opacity=${opacity}:grayscale=${min_val},${max_val} ${aseg_volume}:colormap=lut:opacity=0.85
			convert -flop ${output_dir}/axial.segment.$aid.png ${output_dir}/axial.segment.$aid.png # flip horizontal axis so as to be in neurological coordinates
		done
		pngappend ${output_dir}/axial.segment.55.png + ${output_dir}/axial.segment.70.png + ${output_dir}/axial.segment.85.png + ${output_dir}/axial.segment.100.png + ${output_dir}/axial.segment.115.png ${output_dir}/axial.segment.png
		if [ ! -e $output_dir/axial.segment.png ]
		then
			convert ${output_dir}/axial.segment.55.png ${output_dir}/axial.segment.70.png ${output_dir}/axial.segment.85.png ${output_dir}/axial.segment.100.png ${output_dir}/axial.segment.115.png +append ${output_dir}/axial.segment.png
		fi
	fi
	# Draw with freeview and save sagittal.segment.slices
        if [ ! -e $output_dir/sagittal.segment.png ]; 
	then
        	for sid in 78 98 118 138 158
        	do
                	freeview --viewsize $width $height -viewport sagittal -slice $sid 1 1 -ss ${output_dir}/sagittal.segment.$sid.png -v ${anat_volume}:opacity=${opacity}:grayscale=${min_val},${max_val} ${aseg_volume}:colormap=lut:opacity=0.85 
		done
		pngappend ${output_dir}/sagittal.segment.78.png + ${output_dir}/sagittal.segment.98.png + ${output_dir}/sagittal.segment.118.png + ${output_dir}/sagittal.segment.138.png + ${output_dir}/sagittal.segment.158.png ${output_dir}/sagittal.segment.png
		if [ ! -e $output_dir/sagittal.segment.png ]
		then
			convert ${output_dir}/sagittal.segment.98.png ${output_dir}/sagittal.segment.118.png ${output_dir}/sagittal.segment.138.png ${output_dir}/sagittal.segment.158.png +append ${output_dir}/sagittal.segment.png
		fi
	fi
	# remove remaining files
	if [ ${clean_bool} = "true" ];
	then
    		if [ -e ${output_dir}/coronal.segment.png ];
		then
        		rm ${output_dir}/coronal.segment.*.png
    		fi

    		if [ -e ${output_dir}/axial.segment.png ];
		then
        		rm ${output_dir}/axial.segment.*.png
    		fi

    		if [ -e ${output_dir}/sagittal.segment.png ]; 
		then
        		rm ${output_dir}/sagittal.segment.*.png
    		fi
	fi
	# single summary
	pngappend ${output_dir}/coronal.segment.png - ${output_dir}/axial.segment.png - ${output_dir}/sagittal.segment.png ${output_dir}/summary.segment.png
	if [ ! -e ${output_dir}/summary.segment.png ]
	then
		convert ${output_dir}/coronal.segment.png ${output_dir}/axial.segment.png ${output_dir}/sagittal.segment.png -append ${output_dir}/summary.segment.png
	fi
	title=${subject}.ccs.qcp.anatomy.segment
	convert -font helvetica -fill white -pointsize 20 -draw "text 10,20 '$title'" ${output_dir}/summary.segment.png ${output_dir}/summary.segment.png
	fi
done
