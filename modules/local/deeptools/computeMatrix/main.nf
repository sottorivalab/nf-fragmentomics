/*
 * This process computes a matrix from the given input data.
 */
process COMPUTEMATRIX {
	tag "$meta_sample.sampleid"
	label 'fast_process'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/deeptools:3.5.5--pyhdfd78af_0' :
        'biocontainers/deeptools:3.5.5--pyhdfd78af_0' }"
	
	input:
	// meta_sample [caseid, sampleid, timepoint], bw, meta_target [source, name], bed, blacklist_bed
	tuple val(meta_sample), path(bw), val(meta_target), path(bed), path(blacklist_bed)
	
	output:
	// meta_sample [caseid, sampleid, timepoint], meta_target [source, name], matrix
	tuple val(meta_sample), val(meta_target), path("*_matrix.gz"), emit: matrix
	path "versions.yml"                                          , emit: versions

	when:
	task.ext.when == null || task.ext.when

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
		--sortRegions descend \\
		--binSize ${params.bin_size} \\
		$args

	cat <<-END_VERSIONS > versions.yml
	"${task.process}":
		deeptools: \$(computeMatrix --version | sed -e "s/computeMatrix //g")
	END_VERSIONS
	"""

	stub:
	def prefix = task.ext.prefix ?: bed.baseName
	"""
	touch ${prefix}_matrix.gz

	cat <<-END_VERSIONS > versions.yml
	"${task.process}":
		deeptools: \$(computeMatrix --version | sed -e "s/computeMatrix //g")
	END_VERSIONS
	"""
}