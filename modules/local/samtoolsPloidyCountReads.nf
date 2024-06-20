process SAMTOOLS_PLOIDY_COUNTREADS {

    publishDir "${params.outdir}/${meta.caseid}/${meta.sampleid}/fragmentomics/processed/bam",
        mode:'copy', 
        pattern: "*.csv",
        overwrite:true

    label "normal_process"

    input:
    tuple val(meta), path(bamgain), path(bamneut), path(bamloss)

    output:
    tuple val(meta), path(bamgain), path(bamneut), path(bamloss), path("*.csv"), emit: counts

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.sampleid}"
    """
    module load samtools
    NEUT=`samtools view -c ${bamneut}`
    GAIN=`samtools view -c ${bamgain}`
    LOSS=`samtools view -c ${bamloss}`
    echo -e "${bamloss.name},\$LOSS\n${bamneut.name},\$NEUT\n${bamgain.name},\$GAIN" > ${prefix}.reads.csv
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.sampleid}"
	"""
	touch ${prefix}.reads.csv
	"""
}