##DIRECTORY
workdir=/Volumes/DJICopilot/REST-meta-PD
CCS_DIR=/Users/mac/Projects/CCS

##LOOP GLOBAL METRICS
for metric in alff
do
    echo "Estimating normative charts for ${metric} ..."
    metricdir=${workdir}/nmm/data/${metric}
    cd ${metricdir}
    if [ ! -f centiles_estimate.R ]
    then
	cp ${workdir}/scripts/template_centiles.R ${metricdir}/centiles_estimate.R
    fi
    R CMD BATCH --args centiles_estimate.R
done




