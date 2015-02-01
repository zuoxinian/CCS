#!/usr/bin/env bash

##########################################################################################################################
## CCS SCRIPT TO DO QUALITY ASSURANCE OF STRUCTURAL IMAGE REGISTRATION
##
## !!!!!*****ALWAYS CHECK YOUR REGISTRATIONS*****!!!!!
##
## for more information see lfcd.psych.ac.cn/ccs.html
## Modified by R-fMRI master: Xi-Nian Zuo. Dec. 03, 2011, Institute of Psychology, CAS.
## Email: zuoxn@psych.ac.cn.
##
## Last Modified: 08/01/2014
##
##########################################################################################################################

## full/path/to/site
dir=$1
## full/path/to/site/subject_list
subject_list=$2
## name of anatomical directory
anat_dir_name=$3
## standard template
standard=$4
## refined registration
reg_refine=$5
## name of registration directory
reg_dir=$6

if [ $# -lt 5 ];
then
        echo -e "\033[47;35m Usage: $0 analysis_dir subject_list anat_dir_name standard reg_refine \033[0m"
        exit
fi

## Start scripts
for subject in `cat ${subject_list}`
do
  	echo "Processing ${subject} ..."
  	anat_dir=${dir}/${subject}/${anat_dir_name}
  	## directory setup
	if [ $# -lt 6 ];
	then
        	reg_dir=reg
	fi
	anat_reg_dir=${anat_dir}/${reg_dir}
	mkdir -p ${anat_reg_dir}/vcheck
	cd ${anat_reg_dir}  
	if [ "${reg_refine}" = "true" ]
	then
		slicer fnirt_highres2standard_ref ${standard} -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png
		pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png fnirt_highres2standard1.png
		slicer ${standard} fnirt_highres2standard_ref -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png
		pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png fnirt_highres2standard2.png
		pngappend fnirt_highres2standard1.png - fnirt_highres2standard2.png fnirt_highres2standard_ref.png
		mv fnirt_highres2standard_ref.png vcheck/
		title=${subject}.ccs.qcp.anat.reg.fnirt
        	convert -font helvetica -fill white -pointsize 20 -draw "text 10,20 '$title'" vcheck/fnirt_highres2standard_ref.png vcheck/fnirt_highres2standard_ref.png
	else
		slicer fnirt_highres2standard ${standard} -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png
        	pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png fnirt_highres2standard1.png
        	slicer ${standard} fnirt_highres2standard -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png
        	pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png fnirt_highres2standard2.png
        	pngappend fnirt_highres2standard1.png - fnirt_highres2standard2.png fnirt_highres2standard.png
		mv fnirt_highres2standard.png vcheck/
		title=${subject}.ccs.acp.anat.reg.fnirt
                convert -font helvetica -fill white -pointsize 36 -draw "text 30,50 '$title'" vcheck/fnirt_highres2standard.png vcheck/fnirt_highres2standard.png
	fi
	rm -f sl?.png fnirt_highres2standard1.png fnirt_highres2standard2.png
done
