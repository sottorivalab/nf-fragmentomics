process COVERAGEBAM {
	
	conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/deeptools:3.5.4--pyhdfd78af_1 ' :
        'biocontainers/deeptools:3.5.4--pyhdfd78af_1' }"

	publishDir "${params.outdir}/${meta.caseid}/${meta.sampleid}/fragmentomics/processed/bw", 
		mode:'copy', 
		overwrite:true
	
	label 'heavy_process'
	
	input:
	tuple val(meta), val(ploidy), path(bam), path(bai), path(blacklist_bed)

	output:
	tuple val(meta), val(ploidy), path("*.bw"), emit: bw

	script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${bam.baseName}"
	"""
	bamCoverage \\
		-b $bam \\
		-o ${prefix}.bw \\
		--numberOfProcessors ${task.cpus} \\
		--blackListFileName ${blacklist_bed} \\
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