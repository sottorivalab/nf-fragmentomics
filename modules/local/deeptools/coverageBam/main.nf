/*
 * This process takes a BAM file as input and calculates the coverage.
 */
process COVERAGEBAM {
	tag "$meta.sampleid"
	label 'heavy_process'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/deeptools:3.5.5--pyhdfd78af_0 ' :
        'biocontainers/deeptools:3.5.5--pyhdfd78af_0' }"

	input:
	// meta [caseid, sampleid, timepoint], bam, bai, blacklist_bed
	tuple val(meta), path(bam), path(bai), path(blacklist_bed)

	output:
	// meta [caseid, sampleid, timepoint], bw
	tuple val(meta), path("*.bw"), emit: bw
	path "versions.yml"          , emit: versions

	when:
    task.ext.when == null || task.ext.when

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
		--binSize ${params.bin_size} \\
		$args
	
	cat <<-END_VERSIONS > versions.yml
	"${task.process}":
		deeptools: \$(bamCoverage --version | sed -e "s/bamCoverage //g")
	END_VERSIONS
	"""

	stub:    
    def prefix = task.ext.prefix ?: "${bam.baseName}"
	"""
	touch "${prefix}.bw"

	cat <<-END_VERSIONS > versions.yml
	"${task.process}":
		deeptools: \$(bamCoverage --version | sed -e "s/bamCoverage //g")
	END_VERSIONS
	"""
}