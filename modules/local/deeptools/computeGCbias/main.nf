process COMPUTEGCBIAS {
	
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/deeptools:3.5.5--pyhdfd78af_0' :
        'biocontainers/deeptools:3.5.5--pyhdfd78af_0' }"
	
	label 'heavy_process'

	input:
	tuple val(meta), path(bam), path(bai), path(genome_2bit)    

	output:
	tuple val(meta), path(bam), path(bai), path(genome_2bit), path("*.freq.txt"), emit: freq

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
	"""

	stub:
    def prefix = task.ext.prefix ?: "${meta.sampleid}"
	"""
	touch ${prefix}.freq.txt
	"""
}