ANTsPath=$1
DataPath=$2
OutputPath=$3
prefix=$4
Data=`ls ${DataPath}/*.nii.gz`

${ANTsPath}/antsMultivariateTemplateConstruction2.sh \
  -d 3 \
  -o ${OutputPath}/${prefix}_ \
  -i 10 \
  -g 0.25 \
  -c 4 \
  -k 1 \
  -w 1 \
  -f 8x4x2x1 \
  -s 3x2x1x0 \
  -q 100x70x50x10 \
  -n 1 \
  -r 1 \
  -l 1 \
  -m CC[2] \
  -t BSplineSyN[0.1,26,0] \
  ${inputfile}
