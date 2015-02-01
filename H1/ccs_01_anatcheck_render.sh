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

## set parameters
SUBJECTS_DIR=${dir}
edgethickness=0;
opacity=1; width=500; height=500;


if [ $# -lt 3 ]; 
then
    	echo -e "\033[47;35m Usage: $0 subjects_dir subjects_list anat_dir_name \033[0m"
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
	##PIAL SURFACE
	# Draw with freeview for pial surfaces
	if [ -f ${SUBJECTS_DIR}/${subject}/surf/lh.pial ]
	then
		if [ ! -e $output_dir/pial.lh.png ]; 
		then
			freeview --viewsize $width $height -viewport 3d -ss $output_dir/pial.lh.png -f ${SUBJECTS_DIR}/${subject}/surf/lh.pial:edgethickness=${edgethickness} 
		fi
	fi
	# Draw with freeview for pial surfaces
        if [ -f ${SUBJECTS_DIR}/${subject}/surf/rh.pial ]
        then
                if [ ! -e $output_dir/pial.rh.png ];
                then
                        freeview --viewsize $width $height -viewport 3d -ss $output_dir/pial.rh.png -f ${SUBJECTS_DIR}/${subject}/surf/rh.pial:edgethickness=${edgethickness}
                fi
        fi
	pngappend ${output_dir}/pial.lh.png + ${output_dir}/pial.rh.png ${output_dir}/pial.png
	if [ ! -e ${output_dir}/pial.png ]
	then
		convert ${output_dir}/pial.lh.png ${output_dir}/pial.rh.png +append ${output_dir}/pial.png
	fi
	##WM SURFACE
	# Draw with freeview for wm surfaces
        if [ -f ${SUBJECTS_DIR}/${subject}/surf/lh.white ]
        then
                if [ ! -e $output_dir/white.lh.png ];
                then
                        freeview --viewsize $width $height -viewport 3d -ss $output_dir/white.lh.png -f ${SUBJECTS_DIR}/${subject}/surf/lh.white:edgethickness=${edgethickness}
                fi
        fi
        # Draw with freeview for white surfaces
        if [ -f ${SUBJECTS_DIR}/${subject}/surf/rh.white ]
        then
                if [ ! -e $output_dir/white.rh.png ];
                then
                        freeview --viewsize $width $height -viewport 3d -ss $output_dir/white.rh.png -f ${SUBJECTS_DIR}/${subject}/surf/rh.white:edgethickness=${edgethickness}
                fi
        fi        
	pngappend ${output_dir}/white.lh.png + ${output_dir}/white.rh.png ${output_dir}/white.png
        if [ ! -e ${output_dir}/white.png ]
        then                    
		convert ${output_dir}/white.lh.png ${output_dir}/white.rh.png +append ${output_dir}/white.png
        fi
	##INFLATE SURFACE
	# Draw with freeview for inflated surfaces
        if [ -f ${SUBJECTS_DIR}/${subject}/surf/lh.inflated ]
        then
                if [ ! -e $output_dir/inflated.lh.png ];
                then
                        freeview --viewsize $width $height -viewport 3d -ss $output_dir/inflated.lh.png -f ${SUBJECTS_DIR}/${subject}/surf/lh.inflated:edgethickness=${edgethickness}
                fi
        fi      
        # Draw with freeview for inflated surfaces
        if [ -f ${SUBJECTS_DIR}/${subject}/surf/rh.inflated ]
        then
                if [ ! -e $output_dir/inflated.rh.png ];
                then
                        freeview --viewsize $width $height -viewport 3d -ss $output_dir/inflated.rh.png -f ${SUBJECTS_DIR}/${subject}/surf/rh.inflated:edgethickness=${edgethickness}
                fi
        fi        
	pngappend ${output_dir}/inflated.lh.png + ${output_dir}/inflated.rh.png ${output_dir}/inflated.png
        if [ ! -e ${output_dir}/inflated.png ]
        then                    
                convert ${output_dir}/inflated.lh.png ${output_dir}/inflated.rh.png +append ${output_dir}/inflated.png
        fi	

	# single summary
	pngappend ${output_dir}/pial.png - ${output_dir}/white.png - ${output_dir}/inflated.png ${output_dir}/summary.render.png
	if [ ! -e ${output_dir}/summary.render.png ]
	then
		convert ${output_dir}/pial.png ${output_dir}/white.png ${output_dir}/inflated.png -append ${output_dir}/summary.render.png
	fi
	title=${subject}.ccs.qcp.anatomy.renders
	convert -font helvetica -fill black -pointsize 20 -draw "text 10,20 '$title'" ${output_dir}/summary.render.png ${output_dir}/summary.render.png

done
