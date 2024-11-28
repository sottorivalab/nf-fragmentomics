process CORRECTGCBIAS {
    
	conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/deeptools:3.5.5--pyhdfd78af_0 ' :
        'biocontainers/deeptools:3.5.5--pyhdfd78af_0' }"

	publishDir "${params.outdir}/${meta.caseid}/${meta.sampleid}/fragmentomics/processed/bam", 
		mode:'copy', 
		overwrite:true
	
	label 'heavy_process'
	
    input:
	tuple val(meta), path(bam), path(bai), path(seg), path(freq), path(genome_2bit)

	output:
	tuple val(meta), path("*.gc_correct.bam"), path("*.gc_correct.bam.bai"), path(seg), path(freq), emit: gc_correct

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
	"""

	stub:
    def prefix = task.ext.prefix ?: "${meta.sampleid}"
	"""
	touch ${prefix}.gc_correct.bam
	touch ${prefix}.gc_correct.bam.bai
	"""
}
