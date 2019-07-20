#directory with registration files from Individual to Age-Specific Template
ASTregdir=$1
#Path of Age-Specific Template
AST=$2
#directory with registration files from AST to standard Template
STregdir=$3
#Standard Template Path
ST=$4
#Individual image (brain image or tissue images)
src=$5
#prefix (individual ID or prefix in DT3_Individual_Registraion_To_Template.sh)
prefix=$6
#Output Path
OutputPath=$7
#output prefix
OutPrefix=$8
mkdir -p ${OutputPath}
##Apply transforms from Individual to AST
ASTwarp=`ls ${ASTregdir}/*${prefix}_1Warp.nii.gz`
ASTaffine=`ls ${ASTregdir}/*${prefix}_0GenericAffine.mat`
ASTref=`ls ${ASTregdir}/*${prefix}_Warped.nii.gz`
ASToutput=${OutputPath}/AST_${OutPrefix}.nii.gz
antsApplyTransforms -d 3 -i ${src} -o ${ASToutput} -r ${ASTref} -t ${ASTwarp} -t ${ASTaffine}
##Apply transfroms from AST to ST
STwarp=`ls ${STregdir}/*1Warp.nii.gz`
STaffine=`ls ${STregdir}/*0GenericAffine.mat`
STref=`ls ${STregdir}/*_Warped.nii.gz`
SToutput=${OutputPath}/ST_${OutPrefix}.nii.gz
antsApplyTransforms -d 3 -i ${ASToutput} -o ${AToutput} -r ${STref} -t ${STwarp} -t ${STaffine}
