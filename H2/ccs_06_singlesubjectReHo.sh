##########################################################################################################################
## CCS SCRIPT TO CALCULATE REGIONAL HOMOGENEITY MEASURES OF THE LOW FREQUENCY OSCILLATIONS IN THE BOLD SIGNAL
##
## This script can be run on its own, by filling in the appropriate parameters
##
## Written by Xi-Nian Zuo (zuoxn@psych.ac.cn).
## for more information see LFCD lab. (lfcd.psych.ac.cn)
##
##########################################################################################################################

## analysisdirectory
dir=$1
## full/path/to/subject_list.txt containing subjects you want to run
subject_list=$2
## name of resting-state scan (no extenstion)
rest=$3
## name of anatomical directory
anat_dir_name=$4
## name of functional directory
func_dir_name=$5
## if refine anat registration
do_refine_reg=$6
## standard template which final functional data registered to
standard_template=$7
## standard surface which final functional data registered to
fsaverage=$8
## name of reg dir
reg_dir_name=$9

## frequency band setting: default LP (i.e., low frequency) = 0.01 ; default HP (i.e., high frequency) = 0.1
lp=0.1 ; hp=0.01

## set your desired spatial smoothing FWHM - we use 6 (acquisition voxel size is 3x3x4mm)
FWHM=6 ; sigma=`echo "scale=10 ; ${FWHM}/2.3548" | bc`

if [ $# -lt 8 ];
then
        echo -e "\033[47;35m Usage: $0 analysis_dir subject_list rest_name anat_dir_name func_dir_name do_refine_reg standard_template fsaverage \033[0m"
        exit
fi

echo ---------------------------------------
echo !!!! CALCULATING REHO !!!!
echo ---------------------------------------

 SUBJECTS_DIR=${dir}

if [ $# -lt 9 ];
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
nuisance_dir=${func_dir}/nuisance
if [ ${globalsignal_removal} = 'true' ]
then
        res_dir=${func_dir}/gs-removal
        ReHo_dir=${func_dir}/ReHo-gs
else
        res_dir=${func_dir}
        ReHo_dir=${func_dir}/ReHo
fi

echo --------------------------
echo running subject ${subject}
echo --------------------------

## ReHo Computation
mkdir -p ${ReHo_dir} ; cd ${ReHo_dir}

## CALCULATING ReHo
## Getting the voxel size
vs=`fslsize ../example_func.nii.gz -s | cut -d= -f3`
echo The voxel size is ${vs} ...
dx=`fslsize ../example_func.nii.gz -s | cut -d= -f3 | cut -dx -f1 | cut -c2-5`
dx=`awk -v a="$dx" 'BEGIN{print (a * 100)}'`
dy=`fslsize ../example_func.nii.gz -s | cut -d= -f3 | cut -dx -f2 | cut -c2-5`
dy=`awk -v a="$dy" 'BEGIN{print (a * 100)}'`
dz=`fslsize ../example_func.nii.gz -s | cut -d= -f3 | cut -dx -f3 | cut -c2-5`
dz=`awk -v a="$dz" 'BEGIN{print (a * 100)}'`
for fwhm in 0
do
	rm -f tmp_iso3mm.nii.gz
	if [ $dx -eq $dy -a $dx -eq $dz ]
	then
		ln -s ${res_dir}/${rest}_pp_sm${fwhm}.nii.gz tmp_iso3mm.nii.gz
	else
		## 4. Resampling to 3mm iso-voxel
		3dresample -dxyz 3 3 3 -prefix tmp_iso3mm.nii.gz -inset ${res_dir}/${rest}_pp_sm${fwhm}.nii.gz
	fi
	## 5. Computing Ranks
	echo "Computing ranks"
	3dTsort -overwrite -prefix ${rest}_sm${fwhm}_rank.nii.gz -rank tmp_iso3mm.nii.gz
	echo "Processing ReHo ..."
	## 6. Calculate Mean Ranks
	echo "Computing mean ranks"
	fslmaths ${rest}_sm${fwhm}_rank.nii.gz -kernel 3D -fmean ${rest}_sm${fwhm}_mean_rank.nii.gz
	## 7. Calculate primary constants
	nt=`fslnvols ${rest}_pp_sm${fwhm}.nii.gz` ; echo "There are ${nt} volumes ..."
	echo "Computing two primary constants"
	n1_const=$(echo "scale=20; ${nt}*${nt}*${nt}-${nt}"|bc); echo ${n1_const}
	n2_const=$(echo "scale=20; 3*(${nt}+1)/(${nt}-1)"|bc); echo ${n2_const}
	## 8. Calculate KCC
	echo "Computing KCC"
	fslmaths ${rest}_sm${fwhm}_mean_rank.nii.gz -sqr -Tmean -mul ${nt} -mul 12 -div ${n1_const} -sub ${n2_const} ReHo_sm${fwhm}_iso3mm.nii.gz
	## 9. Back to Native Voxel-size
	rm -f ReHo_sm${fwhm}.nii.gz
	3dresample -master ${func_dir}/${rest}_pp_mask.nii.gz -prefix ReHo_sm${fwhm}.nii.gz -inset ReHo_sm${fwhm}_iso3mm.nii.gz 
	fslmaths ReHo_sm${fwhm}.nii.gz -mas ${func_dir}/${rest}_pp_mask.nii.gz ReHo_sm${fwhm}.nii.gz
	## 10. Z-normalisation across whole brain
	echo "Normalizing ReHo to Z-score across full brain"
	fslstats ReHo_sm${fwhm}.nii.gz -k ${func_dir}/${rest}_pp_mask.nii.gz -m > mean_ReHo_sm${fwhm}.txt ; 
	mean=$( cat mean_ReHo_sm${fwhm}.txt )
	fslstats ReHo_sm${fwhm}.nii.gz -k ${func_dir}/${rest}_pp_mask.nii.gz -s > std_ReHo_sm${fwhm}.txt ; 
	std=$( cat std_ReHo_sm${fwhm}.txt )
	echo $mean $std ${mean_sm} ${std_sm}
	fslmaths ReHo_sm${fwhm}.nii.gz -sub ${mean} -div ${std} -mas ${func_dir}/${rest}_pp_mask.nii.gz ReHo_sm${fwhm}_Z.nii.gz
	if [ ${fwhm} -eq 0 ]
	then
		mri_fwhm --i ReHo_sm${fwhm}_Z.nii.gz --o tmpReHo.nii.gz --smooth-only --fwhm ${FWHM} --mask ${func_dir}/${rest}_pp_mask.nii.gz
	else
		ln -s ReHo_sm${fwhm}_Z.nii.gz tmpReHo.nii.gz
	fi
	## 11. Register Z-transformed ReHo maps to standard space
	if [ "${do_refine_reg}" = "true" ]; 
	then
   		echo Registering Z-transformed ReHo to study-specific template
    		applywarp --ref=${standard_template} --in=tmpReHo.nii.gz --out=fnirt_ReHo_sm${fwhm}_Zmap.nii.gz --warp=${anat_reg_dir}/highres2standard_ref_warp --premat=${func_reg_dir}/example_func2highres.mat
	else
    		echo Registering Z-transformed ReHo to MNI152 template
    		applywarp --ref=${standard_template} --in=tmpReHo.nii.gz --out=fnirt_ReHo_sm${fwhm}_Zmap.nii.gz --warp=${anat_reg_dir}/highres2standard_warp --premat=${func_reg_dir}/example_func2highres.mat
	fi
	rm -rv tmp*.nii.gz
## END OF FWHM LOOP
done
## END OF SUBJECT LOOP
done

cd ${cwd}
