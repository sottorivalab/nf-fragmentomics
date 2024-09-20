process SAMTOOLS_PLOIDY_COUNTREADS {

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.19.2--h50ea8bc_0' :
        'biocontainers/samtools:1.19.2--h50ea8bc_0' }"
        
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