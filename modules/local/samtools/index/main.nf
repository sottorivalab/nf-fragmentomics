process SAMTOOLSINDEX {
	
	conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.19.2--h50ea8bc_0' :
        'biocontainers/samtools:1.19.2--h50ea8bc_0' }"

	publishDir "${params.outdir}/${meta.caseid}/${meta.sampleid}/fragmentomics/processed/bam", 
		mode:'copy', 
		overwrite:true

	label 'normal_process'
	
	input:
	tuple val(meta), val(ploidy), path(bam)

	output:
	tuple val(meta), val(ploidy), path(bam), path("*.bai"), emit: indexed_bam
	
	script:
    def args = task.ext.args ?: ''
	"""
	samtools index -@ ${task.cpus} ${bam} $args
	"""

	stub:
    def prefix = task.ext.prefix ?: "${bam.baseName}"
	"""
	touch ${prefix}.bam.bai
	"""
	
}