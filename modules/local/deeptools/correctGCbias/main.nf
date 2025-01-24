/*
 * Correct GC bias in BAM files
 */ 
process CORRECTGCBIAS {
    tag "$meta.sampleid"	
	label 'process_high'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/deeptools:3.5.5--pyhdfd78af_0' :
        'biocontainers/deeptools:3.5.5--pyhdfd78af_0' }"

    input:
	tuple val(meta), path(bam), path(bai), path(genome_2bit), path(freq)

	output:
	tuple val(meta), path("*.gc_correct.bam"), path("*.gc_correct.bam.bai"), path(freq), emit: gc_correct
	path "versions.yml"                                                                , emit: versions

	when:
    task.ext.when == null || task.ext.when
	
	script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.sampleid}"
	"""
	correctGCBias \\
        -b ${bam} \\
        --effectiveGenomeSize ${params.genome_size} \\
        -g ${genome_2bit} \\
        --GCbiasFrequenciesFile ${freq} \\
        --numberOfProcessors ${task.cpus} \\
        -o ${prefix}.gc_correct.bam \\
        $args
    
	
    cat <<-END_VERSIONS > versions.yml
"${task.process}":
deeptools: \$(correctGCBias --version | sed -e "s/correctGCBias //g")
END_VERSIONS
	"""

	stub:
    def prefix = task.ext.prefix ?: "${meta.sampleid}"
	"""
	touch ${prefix}.gc_correct.bam
	touch ${prefix}.gc_correct.bam.bai

    cat <<-END_VERSIONS > versions.yml
"${task.process}":
deeptools: \$(correctGCBias --version | sed -e "s/correctGCBias //g")
END_VERSIONS
	"""
}
