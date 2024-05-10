process SAMTOOLSFILTERSEG {
    publishDir "${params.outdir}/${sample.caseid}/${sample.id}/fragmentomics/processed/bam", mode:'copy', overwrite:true
    label "hpc_executor"

    if ( "${workflow.stubRun}" == "false" ) {
		cpus = 4
		memory = 16.GB
		time = '2h'
	}
    
    input:
    tuple val(sample), path(bam), path(bai), path(gain), path(neut)

    output:
    tuple val(sample), path("*.NEUT.bam"), path("*.GAIN.bam"), emit: ploidy_bam

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${sample.id}"
    """
    module load samtools
    samtools view -O bam -o ${prefix}.NEUT.bam -L ${neut} ${bam}
    samtools view -O bam -o ${prefix}.GAIN.bam -L ${gain} ${bam}
    """

    stub:
    def prefix = task.ext.prefix ?: "${sample.id}"
	"""
	touch ${prefix}.NEUT.bam
    touch ${prefix}.GAIN.bam
	"""
}