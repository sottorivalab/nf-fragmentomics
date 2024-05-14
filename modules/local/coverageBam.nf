process COVERAGEBAM {
	conda '/home/davide.rambaldi/miniconda3/envs/deeptools'
	publishDir "${params.outdir}/${meta.caseid}/${meta.id}/fragmentomics/processed/bw", mode:'copy', overwrite:true
	label 'hpc_executor'
	
	if ( "${workflow.stubRun}" == "false" ) {
		cpus = 16
		memory = 64.GB
		time = '8h'
	}

	input:
	tuple val(meta), path(bam), path(bai)
	
	output:
	tuple val(meta), path("*.bw"), emit: bw

	script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${bam.baseName}"
	"""
	bamCoverage \\
		-b $bam \\
		-o ${prefix}.bw \\
		--numberOfProcessors ${task.cpus} \\
		--blackListFileName ${params.blacklist_bed} \\
		--centerReads \\
		--binSize ${params.bin_size}
		$args
	"""

	stub:    
    def prefix = task.ext.prefix ?: "${bam.baseName}"
	"""
	touch "${prefix}.bw"
	"""
}