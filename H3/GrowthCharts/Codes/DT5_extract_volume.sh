#subject ID
sub=$1
#individual brain parcellation, output of DT4_Standard_to_Indi.sh
mask=$2
#path of partial volume estimates(PVE) of individual brain gray matter, output of DT2_Individual_Segmentation.sh
gm=$3
#path of output directory
outputdir=$4

maskdir=${outputdir}/mask
mkdir -p ${maskdir}
resultdir=${outputdir}/volresult
mkdir -p ${resultdir}
num=`fslstats ${mask} -R | awk '{print int($2)}'`
for ((P=1; P<=${num}; P++))
do
	k=`printtf "%.3d" "${P}"`
	fslmaths ${mask} -thr $P -uthr $P -bin ${maskdir}/${k}_mask.nii.gz
	fslmaths ${gm} -mul ${outputdir}/${k}_mask.nii.gz ${maskdir}/${sub}_GMpve_${k}.nii.gz
	tmpvol=`fslstats ${outputdir}/${sub}_GMpve_${k}.nii.gz -M -V | awk '{ print $1 * $3 }'`
	subvol="${subvol} ${tmpvol}"
done
echo "${sub} ${subvol}" > ${resultdir}/${sub}_GM_volume.txt
