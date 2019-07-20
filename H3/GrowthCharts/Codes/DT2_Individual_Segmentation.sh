#Path of individual brain images
DataPath=$1
#Path of Age-Specific Templates (Output path in last step)
ASTPath=$2
#Age group or prefix of ASTs
age=$3
#Individual ID
sub=$4
#output Path
outputPath=$5
mkdir -p ${outputPath}
Indiimage=`ls ${DataPath}/${sub}*`
##fast segmentation
fast -n 3 -g -b -o ${outputPath}/${sub}  -p ${Indiimage}
##apply registration transforms to indi images
for segimg in `ls ${outputPath}/${sub}_pve*`
do
	antsApplyTransforms -d 3 -i ${segimg} -o ${segimg%%\.*}_${age}.nii.gz -r ${ASTPath}/${age}*template0.nii.gz -t ${ASTPath}/*${sub}*1Warp.nii.gz -t ${ASTPath}/*${sub}*GenericAffine.mat

done


