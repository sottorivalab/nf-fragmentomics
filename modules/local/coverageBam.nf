process COVERAGEBAM {
	conda '/home/davide.rambaldi/miniconda3/envs/deeptools'
	publishDir "${params.outdir}/${meta.caseid}/${meta.id}/fragmentomics/processed/bw", mode:'copy', overwrite:true

	if ( "${workflow.stubRun}" == "false" ) {
		cpus = 32
		memory = 128.GB
	}

	input:
	tuple val(meta), path(bam), path(bai)
	
	output:
	tuple val(meta), path("*.bw"), emit: bw

	script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
	"""
	bamCoverage \\
		-b $bam \\
		-o ${prefix}.bw \\
		--numberOfProcessors ${task.cpus} \\
		--blackListFileName ${params.blacklist_bed} \\
		$args
	"""

	stub:    
    def prefix = task.ext.prefix ?: "${meta.id}"
	"""
	touch "${prefix}.bw"
	"""
}