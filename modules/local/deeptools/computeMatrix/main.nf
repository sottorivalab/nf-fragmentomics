/*
 * This process computes a list of matrixes from the given input data.
 */
process COMPUTEMATRIX {
	tag "$meta_sample.sampleid"
	label 'process_high'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/deeptools:3.5.5--pyhdfd78af_0' :
        'biocontainers/deeptools:3.5.5--pyhdfd78af_0' }"
	
	input:
	tuple val(meta_sample), path(bw), path(blacklist_bed), val(source), val(names), path(beds)
	
	output:
	tuple val(meta_sample), val(source), path("*_matrix.gz"), emit: matrix
	path "versions.yml"                                     , emit: versions

	when:
	task.ext.when == null || task.ext.when

	script:
    def args = task.ext.args ?: ''    
	"""
	for BED in ${beds.join(' ')} ; do
		BASENAME=\$(basename \${BED} .bed)
        OUTPUT_FILE=\${BASENAME}_matrix.gz
		
		computeMatrix reference-point \\
			--referencePoint center \\
			-S ${bw} \\
			-R \${BED} \\
			-a ${params.target_expand_sx} \\
			-b ${params.target_expand_dx} \\
			-o \${OUTPUT_FILE} \\
			--blackListFileName ${blacklist_bed} \\
			--numberOfProcessors ${task.cpus} \\
			--sortRegions descend \\
			--binSize ${params.bin_size} \\
			$args > \${BASENAME}.computeMatrix.log 2>&1			
			
	done

	cat <<-END_VERSIONS > versions.yml
	"${task.process}":
	deeptools: \$(computeMatrix --version | sed -e "s/computeMatrix //g")
	END_VERSIONS
	"""

	stub:
	"""
	for BED in ${beds.join(' ')} ; do
		BASENAME=\$(basename \${BED} .bed)
		OUTPUT_FILE=\${BASENAME}_matrix.gz
		touch \${OUTPUT_FILE}
	done

	cat <<-END_VERSIONS > versions.yml
	"${task.process}":
	deeptools: \$(computeMatrix --version | sed -e "s/computeMatrix //g")
	END_VERSIONS
	"""
}