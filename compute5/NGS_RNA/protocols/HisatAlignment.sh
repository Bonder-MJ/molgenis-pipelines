#MOLGENIS nodes=1 ppn=8 mem=8gb walltime=05:00:00

#string project
#string stage
#string checkStage
#string hisatIndex
#string leftbarcodefqgz
#string rightbarcodefqgz
#string intermediateDir
#string alignedSam
#string alignedFilteredBam
#string sortedBam
#string sortedBai
#string hisatVersion
#string externalSampleID
#string samtoolsVersion
#string picardVersion
#string sequencer
#string library
#string flowcell
#string run
#string barcode
#string lane
#string tempDir
#string filePrefix
#string picardJar
#string seqType

if [ ${seqType} == "SR" ]
then

	input="-U ${leftbarcodefqgz}"
	echo "Single end alignment of ${leftbarcodefqgz}"
else
	input="-1 ${leftbarcodefqgz} -2 ${rightbarcodefqgz}"
	echo "Paired end alignment of ${leftbarcodefqgz} and ${rightbarcodefqgz}"
fi

makeTmpDir ${alignedSam}
tmpAlignedSam=${MC_tmpFile}

makeTmpDir ${alignedFilteredBam}
tmpAlignedFilteredBam=${MC_tmpFile}

makeTmpDir ${sortedBam}
tmpSortedBam=${MC_tmpFile}

makeTmpDir ${sortedBai}
tmpSortedBai=${MC_tmpFile}


#Load modules
${stage} ${hisatVersion}
${stage} ${samtoolsVersion}
${stage} ${picardVersion}

#check modules
${checkStage}

echo "## "$(date)" Start $0"

	hisat -x ${hisatIndex} \
	${input} \
	-p 8 \
	--rg-id ${externalSampleID} \
	--rg PL:illumina \
	--rg PU:${sequencer}_${flowcell}_${run}_${lane}_${barcode} \
	--rg LB:${sequencer}_${flowcell}_${run}_${lane}_${barcode} \
	--rg SM:${externalSampleID} \
	-S ${tmpAlignedSam} > ${intermediateDir}/${externalSampleID}_L${lane}.hisat.log 2>&1

	perl -nle 'print $2,"|\t",$1 while (m%^[ ]*([.0-9\%]+\s\(.+\)|[.0-9\%]+).(.+)%g);' ${intermediateDir}/${externalSampleID}_L${lane}.hisat.log > ${intermediateDir}/${externalSampleID}.hisat.final.log

sed '/NH:i:[^1]/d' ${tmpAlignedSam} | samtools view -h -b - > ${tmpAlignedFilteredBam}

	echo "Reads with flag NH:i:[2+] where filtered out (only leaving 'unique' mapping reads)."
	rm ${tmpAlignedSam}
	echo "returncode: $?";
	echo "succes moving files";


echo "## "$(date)" Start $0"

java -XX:ParallelGCThreads=4 -jar -Xmx6g ${EBROOTPICARD}/${picardJar} SortSam \
	INPUT=${tmpAlignedFilteredBam} \
	OUTPUT=${tmpSortedBam} \
 	SO=coordinate \
	CREATE_INDEX=true \
	VALIDATION_STRINGENCY=LENIENT \
	TMP_DIR=${tempDir}


	echo "returncode: $?";
	mv ${tmpSortedBam} ${sortedBam}
	mv ${tmpSortedBai} ${sortedBai}
	echo "succes moving files";

	echo "## "$(date)" ##  $0 Done "
