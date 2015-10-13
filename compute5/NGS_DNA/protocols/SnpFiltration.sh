#MOLGENIS walltime=23:59:00 mem=10gb

#Parameter mapping
#string stage
#string checkStage
#string gatkVersion
#string gatkJar
#string tempDir
#string intermediateDir
#string indexFile
#string variantAnnotatorSampleOutputSnpsVcf
#string variantAnnotatorSampleOutputSnpsFilteredVcf
#string tmpDataDir
#string project

sleep 5

#Function to check if array contains value
array_contains () { 
    local array="$1[@]"
    local seeking=$2
    local in=1
    for element in "${array[@]}"; do
        if [[ "$element" == "$seeking" ]]; then
            in=0
            break
        fi
    done
    return $in
}

INPUTS=()

#Load GATK module
${stage} ${gatkVersion}
${checkStage}

makeTmpDir ${variantAnnotatorSampleOutputSnpsFilteredVcf}
tmpVariantAnnotatorSampleOutputSnpsFilteredVcf=${MC_tmpFile}

#Run GATK VariantFiltration to filter called SNPs on 

java -XX:ParallelGCThreads=4 -Xmx8g -Xms6g -jar ${EBROOTGATK}/${gatkJar} \
-Djava.io.tmpdir=${tempDir} \
-T VariantFiltration \
-R ${indexFile} \
-o ${tmpVariantAnnotatorSampleOutputSnpsFilteredVcf} \
--variant ${variantAnnotatorSampleOutputSnpsVcf} \
--filterExpression "QD < 2.0" \
--filterName "filterQD" \
--filterExpression "MQ < 25.0" \
--filterName "filterMQ" \
--filterExpression "FS > 60.0" \
--filterName "filterFS" \
--filterExpression "MQRankSum < -12.5" \
--filterName "filterMQRankSum" \
--filterExpression "ReadPosRankSum < -8.0" \
--filterName "filterReadPosRankSum"

echo -e "\nVariantFiltering finished succesfull. Moving temp files to final.\n\n"
mv ${tmpVariantAnnotatorSampleOutputSnpsFilteredVcf} ${variantAnnotatorSampleOutputSnpsFilteredVcf}
