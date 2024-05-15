process SAMTOOLSCOUNTREADS {

    publishDir "${params.outdir}/${meta.caseid}/${meta.sampleid}/fragmentomics/processed/bam",
        mode:'copy', 
        pattern: "*.csv",
        overwrite:true

    label "normal_process"

    input:
    tuple val(meta), path(bamgain), path(bamneut)

    output:
    tuple val(meta), path(bamgain), path(bamneut), path("*.csv"), emit: counts

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.sampleid}"
    """
    module load samtools
    NEUT=`samtools view -c ${bamneut}`
    GAIN=`samtools view -c ${bamgain}`
    echo -e "${bamneut.name},\$NEUT\n${bamgain.name},\$GAIN" > ${prefix}.reads.csv
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.sampleid}"
	"""
	touch ${prefix}.reads.csv
	"""
}