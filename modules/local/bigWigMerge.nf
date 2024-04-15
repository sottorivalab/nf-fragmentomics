process BIGWIG_MERGE {    
    publishDir "${params.outdir}/TIMEPOINTS/processed/", mode:'copy', overwrite:true
    if ( "${workflow.stubRun}" == "false" ) {
		cpus = 1
		memory = 8.GB
	}

    input:
    tuple val(timepoint), val(metas), path(bws)

    output:
    tuple val(timepoint), path("MISSONI_${timepoint}.bedGraph")

    script:
    """
    module load ucsc-tools
    echo MISSONI_${timepoint}.bw
    bigWigMerge ${bws.join(' ')} MISSONI_${timepoint}.bedGraph
    """

    stub:
    """
    touch MISSONI_${timepoint}.bedGraphs
    """
}