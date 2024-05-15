process SAMTOOLSINDEX {
	
	publishDir "${params.outdir}/${meta.caseid}/${meta.sampleid}/fragmentomics/processed/bam", 
		mode:'copy', 
		overwrite:true

	label 'normal_process'
	
	input:
	tuple val(meta), path(bam)

	output:
	tuple val(meta), path(bam), path("*.bai"), emit: indexed_bam
	
	script:
    def args = task.ext.args ?: ''
	"""
	module load samtools
	samtools index -@ ${task.cpus} ${bam} $args
	"""

	stub:
    def prefix = task.ext.prefix ?: "${bam.baseName}"
	"""
	touch ${prefix}.bam.bai
	"""
	
}