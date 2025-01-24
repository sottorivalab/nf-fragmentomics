/*
 * COMPUTEGCBIAS in bam files
 */
process COMPUTEGCBIAS {
	tag "$meta.sampleid"	
	label 'process_high'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/deeptools:3.5.5--pyhdfd78af_0' :
        'biocontainers/deeptools:3.5.5--pyhdfd78af_0' }"	

	input:
	// meta [caseid, sampleid, timepoint], bam, bai, genome_2bit
	tuple val(meta), path(bam), path(bai), path(genome_2bit)    

	output:
	// meta [caseid, sampleid, timepoint], bam, bai, genome_2bit, freq
	tuple val(meta), path(bam), path(bai), path(genome_2bit), path("*.freq.txt"), emit: freq
	path "versions.yml"                                                         , emit: versions

	when:
    task.ext.when == null || task.ext.when
	
	script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.sampleid}"
	"""
	computeGCBias \\
        -b ${bam} \\
        --effectiveGenomeSize ${params.genome_size} \\
        -g ${genome_2bit} \\
        --GCbiasFrequenciesFile ${prefix}.freq.txt \\
        --numberOfProcessors ${task.cpus} \\
        $args
	
	cat <<-END_VERSIONS > versions.yml
"${task.process}":
deeptools: \$(computeGCBias --version | sed -e "s/computeGCBias //g")
END_VERSIONS
	"""

	stub:
    def prefix = task.ext.prefix ?: "${meta.sampleid}"
	"""
	touch ${prefix}.freq.txt
	
	cat <<-END_VERSIONS > versions.yml
"${task.process}":
deeptools: \$(computeGCBias --version | sed -e "s/computeGCBias //g")
END_VERSIONS
	"""
}