##########################################################################################################################
## CCS SCRIPT TO DO QUALITY ASSURANCE OF FUNCTIONAL IMAGE REGISTRATION
##
## !!!!!*****ALWAYS CHECK YOUR REGISTRATIONS*****!!!!!
##
## for more information see lfcd.psych.ac.cn/ccs.html
## R-fMRI master: Xi-Nian Zuo. Dec. 03, 2011, Institute of Psychology, CAS.
##
## Email: zuoxn@psych.ac.cn.
##########################################################################################################################

## full/path/to/site
dir=$1
## full/path/to/site/subject_list
subject_list=$2
## name of anatomical directory
func_dir_name=$3
## standard template
standard=$4

if [ $# -lt 4 ];
then
        echo -e "\033[47;35m Usage: $0 analysis_dir subject_list func_dir_name standard \033[0m"
        exit
fi

## Start scripts
for subject in `cat ${subject_list}`
do
        echo "Processing ${subject} ..."
        func_dir=${dir}/${subject}/${func_dir_name}
        func_reg_dir=${func_dir}/reg
        mkdir -p ${func_reg_dir}/vcheck
        cd ${func_reg_dir}
	slicer fnirt_example_func2standard ${standard} -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png
	pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png fnirt_example_func2standard1.png
	slicer ${standard} fnirt_example_func2standard -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png
	pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png fnirt_example_func2standard2.png
	pngappend fnirt_example_func2standard1.png - fnirt_example_func2standard2.png fnirt_example_func2standard.png
	mv fnirt_example_func2standard.png vcheck/
	title=${subject}.ccs.func.fnirt.reg
        convert -font helvetica -fill white -pointsize 36 -draw "text 30,50 '$title'" vcheck/fnirt_example_func2standard.png vcheck/fnirt_example_func2standard.png
	rm -f sl?.png fnirt_example_func2standard?.png
done

