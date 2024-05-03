process BEDGRAPHTOBIGWIG {
    publishDir "${params.outdir}/TIMEPOINTS/processed/bw", mode:'copy', overwrite:true
    if ( "${workflow.stubRun}" == "false" ) {
		cpus = 1
		memory = 24.GB
        time = '8h'
	}

    input:
    tuple val(timepoint), path(bedgraph)

    output:
    tuple val(timepoint), path("COHORT_${timepoint}.bw"), emit: bw

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "COHORT_${timepoint}"
    """
    module load ucsc-tools
    bedGraphToBigWig ${bedgraph} ${params.chr_sizes} ${prefix}.bw 
    """

    stub:
    def prefix = task.ext.prefix ?: "COHORT_${timepoint}"
    """
    touch ${prefix}.bw
    """
}