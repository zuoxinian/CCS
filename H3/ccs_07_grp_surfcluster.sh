glmdir=$1 ; contrast=$2 ; hemi=$3 ; fsaverage=$4
## tmin=1.3010: p < 0.05; tmin=1.6021: p < 0.025 (corrected with two hemispheres)
cd ${glmdir}/${contrast}
mri_surfcluster --in sig.cw.pos.mgh --thmin 1.6021 --no-adjust --sign abs --subject ${fsaverage} --hemi ${hemi} --annot aparc.a2009s --mask ../mask.mgh --cwsig sigclusters.cw.pos.mgh --sum sigclusters.cw.pos.txt
mri_surfcluster --in sig.cw.neg.mgh --thmin 1.6021 --no-adjust --sign abs --subject ${fsaverage} --hemi ${hemi} --annot aparc.a2009s --mask ../mask.mgh --cwsig sigclusters.cw.neg.mgh --sum sigclusters.cw.neg.txt
