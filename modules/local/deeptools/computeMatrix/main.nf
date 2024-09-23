process COMPUTEMATRIX {
	
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/deeptools:3.5.4--pyhdfd78af_1' :
        'biocontainers/deeptools:3.5.4--pyhdfd78af_1' }"

    publishDir "${params.outdir}/${meta_sample.caseid}/${meta_sample.sampleid}/fragmentomics/processed/matrix/${meta_target.source}/${meta_target.name}", 
		mode:'copy', 
		overwrite:true
	
	label 'fast_process'

	input:
	tuple val(meta_sample), path(bw), val(meta_target), path(bed), path(blacklist_bed)
	
	output:
	tuple val(meta_sample), val(meta_target), path("*_matrix.gz"), emit: matrix

	script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: bed.baseName
	"""
	computeMatrix reference-point \\
		--referencePoint center \\
		-S ${bw} \\
		-R ${bed} \\
		-a ${params.target_expand_sx} \\
		-b ${params.target_expand_dx} \\
		-o ${prefix}_matrix.gz \\
		--blackListFileName ${blacklist_bed} \\
		--numberOfProcessors ${task.cpus} \\
		$args
	"""

	stub:
	def prefix = task.ext.prefix ?: bed.baseName
	"""
	touch ${prefix}_matrix.gz
	"""
}