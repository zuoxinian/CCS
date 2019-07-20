#Path of Age-Specific Templates (output Path in step 1 template construction)
ASTPath=$1
#AST prefix
AST=$2
#Path of individual brain image
source=$3
#individual ID or prefix
prefix=$4
#output path
OutputPath=$5
target=`ls ${ASTPath}/${AST}*template*`
outdir=${OutputPath}/${sub}
antsRegistration \
 -d 3 \
--float 1 \
--verbose 1 \
-u 1 \
-w [0.01,0.99] \
-z 1 \
-r [${target},${source},1] \
-t Rigid[0.1] \
-m MI[${target},${source},1,32,Regular,0.25] \
-c [1000x500x250x0,1e-6,10] \
-f 6x4x2x1 \
-s 4x2x1x0 \
-t Affine[0.1] \
-m MI[${target},${source},1,32,Regular,0.25] \
-c [1000x500x250x0,1e-6,10] \
-f 6x4x2x1 \
-s 4x2x1x0 \
-t BSplineSyN[0.1,26,0] \
-m CC[${target},${source},1,4] \
-c [100x70x50x10,1e-9,10] \
-f 8x4x2x1 \
-s 3x2x1x0 \
-o [${outdir}/${AST}_${prefix}_,${outdir}/${AST}_${prefix}_Warped.nii.gz,${outdir}/${AST}_${prefix}_InverseWarped.nii.gz]
