process COMPUTEMATRIX {
	conda '/home/davide.rambaldi/miniconda3/envs/deeptools'
    publishDir "${params.outdir}/${meta_sample.caseid}/${meta_sample.id}/fragmentomics/processed/matrix/${meta_target.source}/${meta_target.name}", mode:'copy', overwrite:true	

	if ( "${workflow.stubRun}" == "false" ) {
		cpus = 32
		memory = 128.GB
	}
	
	input:
	tuple val(meta_sample), path(bw), val(meta_target), path(bed)
	
	output:
	tuple val(meta_sample), val(meta_target), path("${meta_sample.id}_${meta_target.name}_matrix.gz"), emit: matrix

	script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta_sample.id}_${meta_target.name}"
	"""
	computeMatrix reference-point \\
        --referencePoint center \\
        -S $bw \\
        -R $bed \\
        -a 4000 \\
        -b 4000 \\
        -o ${prefix}_matrix.gz \\
		--blackListFileName ${params.blacklist_bed} \\
        --numberOfProcessors ${task.cpus} \\
        $args
	"""

	stub:
    def prefix = task.ext.prefix ?: "${meta_sample.id}_${meta_target.name}"
	"""
	touch ${prefix}_matrix.gz
	"""
}