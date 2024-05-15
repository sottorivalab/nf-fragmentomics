process CORRECTGCBIAS {
    conda '/home/davide.rambaldi/miniconda3/envs/deeptools'

	publishDir "${params.outdir}/${meta.caseid}/${meta.sampleid}/fragmentomics/processed/bam", 
		mode:'copy', 
		overwrite:true
	
	label 'heavy_process'
	
    input:
	tuple val(meta), path(bam), path(bai), path(seg), path(freq)

	output:
	tuple val(meta), path("*.gc_correct.bam"), path("*.gc_correct.bam.bai"), path(seg), path(freq), emit: gc_correct

	script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.sampleid}"
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
    def prefix = task.ext.prefix ?: "${meta.sampleid}"
	"""
	touch ${prefix}.gc_correct.bam
	touch ${prefix}.gc_correct.bam.bai
	"""
}
