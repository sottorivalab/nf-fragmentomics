process SAMTOOLSINDEX {
	publishDir "${params.outdir}/${meta.caseid}/${meta.id}/fragmentomics/processed/bam", mode:'copy', overwrite:true

	if ( "${workflow.stubRun}" == "false" ) {
		cpus = 4
		memory = 16.GB
	}
	
	input:
	tuple val(meta), path(bam)

	output:
	tuple val(meta), path("*.bai"), emit: bai
	
	script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
	"""
	module load samtools
	samtools index -@ ${task.cpus} $bam $args
	"""

	stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
	"""
	touch ${prefix}.gc_correct.bam.bai
	"""
	
}