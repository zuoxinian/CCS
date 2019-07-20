#directory with registration files from Individual to Age-Specific Template
ASTregdir=$1
#Path of Age-Specific Template
AST=$2
#directory with registration files from AST to standard Template
STregdir=$3
#Standard Template Path
ST=$4
#Atlas information defined on Standard Template (i.e. Parcellation mask)
src=$5
#prefix (individual ID or prefix in DT3_Individual_Registraion_To_Template.sh)
prefix=$6
#Output Path
OutputPath=$7
#output prefix
OutPrefix=$8
mkdir -p ${OutputPath}
##Apply transfroms from ST to AST
STInwarp=`ls ${STregdir}/*1InverseWarp.nii.gz`
STaffine=`ls ${STregdir}/*0GenericAffine.mat`
STInref=`ls ${STregdir}/*_InverseWarped.nii.gz`
SToutput=${OutputPath}/AST_${OutPrefix}.nii.gz
antsApplyTransforms -d 3 -n NearestNeighbor -i ${src} -o ${SToutput} -r ${STInref}  -t [${STaffine},1] -t ${STInwarp}
##Apply transforms from AST to Indi
ASTInwarp=`ls ${ASTregdir}/*${prefix}_1InverseWarp.nii.gz`
ASTaffine=`ls ${ASTregdir}/*${prefix}_0GenericAffine.mat`
ASTInref=`ls ${ASTregdir}/*${prefix}_InverseWarped.nii.gz`
ASToutput=${OutputPath}/Indi_${OutPrefix}.nii.gz
antsApplyTransforms -d 3 -n NearestNeighbor -i ${SToutput} -o ${ASToutput} -r ${ASTInref}  -t [${ASTaffine},1] -t ${ASTInwarp}
