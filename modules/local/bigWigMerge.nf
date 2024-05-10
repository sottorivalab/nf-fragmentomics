process BIGWIG_MERGE {    
    publishDir "${params.outdir}/TIMEPOINTS/processed/bedgraph", mode:'copy', overwrite:true
    label 'hpc_executor'
    
    if ( "${workflow.stubRun}" == "false" ) {
		cpus = 1
		memory = 24.GB
        time = '8h'
	}

    input:
    tuple val(timepoint), val(metas), path(bws)

    output:
    tuple val(timepoint), path("COHORT_${timepoint}.bedGraph"), emit: bedgraph

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "COHORT_${timepoint}"
    """
    module load ucsc-tools    
    bigWigMerge ${bws.join(' ')} ${prefix}.bedGraph
    """

    stub:
    def prefix = task.ext.prefix ?: "COHORT_${timepoint}"
    """
    touch ${prefix}.bedGraph
    """
}