process COVERAGEBAM {
	conda '/home/davide.rambaldi/miniconda3/envs/deeptools'

	publishDir "${params.outdir}/${meta.caseid}/${meta.sampleid}/fragmentomics/processed/bw", 
		mode:'copy', 
		overwrite:true
	
	label 'heavy_process'
	
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