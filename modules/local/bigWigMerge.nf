process BIGWIG_MERGE {    
    publishDir "${params.outdir}/TIMEPOINTS/processed/bedgraph/${ploidy}", mode:'copy', overwrite:true
    label 'hpc_executor'
    
    if ( "${workflow.stubRun}" == "false" ) {
		cpus = 1
		memory = 24.GB
        time = '8h'
	}

    input:
    tuple val(timepoint), val(ploidy), val(meta_sample), path(bws)

    output:
    tuple val(timepoint), val(ploidy), path("COHORT_${timepoint}_${ploidy}.bedGraph"), emit: bedgraph

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "COHORT_${timepoint}_${ploidy}"
    """
    module load ucsc-tools    
    bigWigMerge ${bws.join(' ')} ${prefix}.bedGraph
    """

    stub:
    def prefix = task.ext.prefix ?: "COHORT_${timepoint}_${ploidy}"
    """
    touch ${prefix}.bedGraph
    """
}