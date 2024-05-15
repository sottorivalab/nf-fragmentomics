process COMPUTEMATRIX {
	conda '/home/davide.rambaldi/miniconda3/envs/deeptools'

    publishDir "${params.outdir}/${meta_sample.caseid}/${meta_sample.sampleid}/fragmentomics/processed/matrix/${meta_target.source}/${meta_target.name}/${meta_ploidy.type}", 
		mode:'copy', 
		overwrite:true
	
	label 'heavy_process'

	input:
	tuple val(meta_sample), val(meta_ploidy), path(bw), val(meta_target), val(meta_ploidy_target), path(bed)
	
	output:
	tuple val(meta_sample), val(meta_ploidy), val(meta_target), val(meta_ploidy_target), path("*_matrix.gz"), emit: matrix

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
		--blackListFileName ${params.blacklist_bed} \\
		--numberOfProcessors ${task.cpus} \\
		$args
	"""

	stub:
	def prefix = task.ext.prefix ?: bed.baseName
	"""
	touch ${prefix}_matrix.gz
	"""
}