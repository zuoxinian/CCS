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
	if [ -f ${SUBJECTS_DIR}/${subject}/surf/lh.pial ]
	then
	# Draw with freeview and save coronal slices
	if [ ! -e $output_dir/coronal.png ]; 
	then
    		for coronal in 64 96 128 160 192
        	do
			freeview --viewsize $width $height -viewport coronal -slice 1 1 $coronal -ss $output_dir/coronal.$coronal.png -v ${anat_volume}:opacity=${opacity}:grayscale=${min_val},${max_val} -f ${SUBJECTS_DIR}/${subject}/surf/lh.white:edgecolor=$edgecolorwm:edgethickness=${edgethickness} -f ${SUBJECTS_DIR}/${subject}/surf/rh.white:edgecolor=$edgecolorwm:edgethickness=${edgethickness} -f ${SUBJECTS_DIR}/${subject}/surf/lh.pial:edgecolor=$edgecolorpial:edgethickness=${edgethickness} -f ${SUBJECTS_DIR}/${subject}/surf/rh.pial:edgecolor=$edgecolorpial:edgethickness=${edgethickness}
			convert -crop 280x300+110+50 ${output_dir}/coronal.$coronal.png ${output_dir}/coronal.$coronal.png
            		convert -flop ${output_dir}/coronal.$coronal.png ${output_dir}/coronal.$coronal.png # flip horizontal axis so as to be in neurological coordinates
    		done
    		pngappend ${output_dir}/coronal.64.png + ${output_dir}/coronal.96.png + ${output_dir}/coronal.128.png + ${output_dir}/coronal.160.png + ${output_dir}/coronal.192.png ${output_dir}/coronal.png
		if [ ! -e ${output_dir}/coronal.png ]
		then
			convert ${output_dir}/coronal.64.png ${output_dir}/coronal.96.png ${output_dir}/coronal.128.png ${output_dir}/coronal.160.png ${output_dir}/coronal.192.png +append ${output_dir}/coronal.png
		fi
	fi
	# Draw with freeview and save axial slices
        if [ ! -e $output_dir/axial.png ]; 
	then
        	for axial in 55 70 85 100 115 
        	do      
                	freeview --viewsize $width $height -viewport axial -slice 1 $axial 1 -ss ${output_dir}/axial.$axial.png -v ${anat_volume}:opacity=${opacity}:grayscale=${min_val},${max_val} -f ${SUBJECTS_DIR}/${subject}/surf/lh.white:edgecolor=$edgecolorwm:edgethickness=${edgethickness} -f ${SUBJECTS_DIR}/${subject}/surf/rh.white:edgecolor=$edgecolorwm:edgethickness=${edgethickness} -f ${SUBJECTS_DIR}/${subject}/surf/lh.pial:edgecolor=$edgecolorpial:edgethickness=${edgethickness} -f ${SUBJECTS_DIR}/${subject}/surf/rh.pial:edgecolor=$edgecolorpial:edgethickness=${edgethickness}
			convert -crop 280x350+110+75 ${output_dir}/axial.$axial.png ${output_dir}/axial.$axial.png
        		convert -flop ${output_dir}/axial.$axial.png ${output_dir}/axial.$axial.png # flip horizontal axis so as to be in neurological coordinates
		done
		pngappend ${output_dir}/axial.55.png + ${output_dir}/axial.70.png + ${output_dir}/axial.85.png + ${output_dir}/axial.100.png + ${output_dir}/axial.115.png ${output_dir}/axial.png
		if [ ! -e $output_dir/axial.png ]
		then
			convert ${output_dir}/axial.55.png ${output_dir}/axial.70.png ${output_dir}/axial.85.png ${output_dir}/axial.100.png ${output_dir}/axial.115.png +append ${output_dir}/axial.png
		fi
	fi
	# Draw with freeview and save sagittal slices
        if [ ! -e $output_dir/sagittal.png ]; 
	then
        	for sagittal in 98 118 138 158
        	do
                	freeview --viewsize $width $height -viewport sagittal -slice $sagittal 1 1 -ss ${output_dir}/sagittal.$sagittal.png -v ${anat_volume}:opacity=${opacity}:grayscale=${min_val},${max_val} -f ${SUBJECTS_DIR}/${subject}/surf/lh.white:edgecolor=$edgecolorwm:edgethickness=${edgethickness} -f ${SUBJECTS_DIR}/${subject}/surf/rh.white:edgecolor=$edgecolorwm:edgethickness=${edgethickness} -f ${SUBJECTS_DIR}/${subject}/surf/lh.pial:edgecolor=$edgecolorpial:edgethickness=${edgethickness} -f ${SUBJECTS_DIR}/${subject}/surf/rh.pial:edgecolor=$edgecolorpial:edgethickness=${edgethickness}
			convert -crop 350x275+60+65 ${output_dir}/sagittal.$sagittal.png ${output_dir}/sagittal.$sagittal.png
		done
		pngappend ${output_dir}/sagittal.98.png + ${output_dir}/sagittal.118.png + ${output_dir}/sagittal.138.png + ${output_dir}/sagittal.158.png ${output_dir}/sagittal.png
		if [ ! -e $output_dir/sagittal.png ]
		then
			convert ${output_dir}/sagittal.98.png ${output_dir}/sagittal.118.png ${output_dir}/sagittal.138.png ${output_dir}/sagittal.158.png +append ${output_dir}/sagittal.png
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
	if [ ! -e ${output_dir}/summary.png ]
	then
		convert ${output_dir}/coronal.png ${output_dir}/axial.png ${output_dir}/sagittal.png -append ${output_dir}/summary.png
	fi
	title=${subject}.ccs.fmri.anatomy
	convert -font helvetica -fill white -pointsize 36 -draw "text 10,10 '$title'" ${output_dir}/summary.png ${output_dir}/summary.png
	fi
done
