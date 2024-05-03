process CORRECTGCBIAS {
    conda '/home/davide.rambaldi/miniconda3/envs/deeptools'
	publishDir "${params.outdir}/${meta.caseid}/${meta.id}/fragmentomics/processed/bam", mode:'copy', overwrite:true

    if ( "${workflow.stubRun}" == "false" ) {
		cpus = 16
		memory = 64.GB
		time = '8h'
	}

    input:
	tuple val(meta), path(freq), path(bam), path(bai)

	output:
	tuple val(meta), path("*.gc_correct.bam"), emit: gc_correct

	script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
	"""
	correctGCBias \\
        -b ${bam} \\
        --effectiveGenomeSize ${params.genome_size} \\
        -g ${params.genome_2bit} \\
        --GCbiasFrequenciesFile ${freq} \\
        --numberOfProcessors ${task.cpus} \\
        -o ${prefix}.gc_correct.bam \\
        $args
	"""

	stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
	"""
	touch ${prefix}.gc_correct.bam
	"""
}
