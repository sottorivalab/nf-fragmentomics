process COMPUTEGCBIAS {
    conda '/home/davide.rambaldi/miniconda3/envs/deeptools'	
	
	label 'heavy_process'

	input:
	tuple val(meta), path(bam), path(bai), path(seg)

	output:
	tuple val(meta), path(bam), path(bai), path(seg), path("*.freq.txt"), emit: bam_with_freq

	script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.sampleid}"
	"""
	computeGCBias \\
        -b ${bam} \\
        --effectiveGenomeSize ${params.genome_size} \\
        -g ${params.genome_2bit} \\
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