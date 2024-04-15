process PEAK_REPORT {
    publishDir "${params.outdir}/${meta_sample.caseid}/${meta_sample.id}/fragmentomics/reports/", mode:'copy', overwrite:true

    if ( "${workflow.stubRun}" == "false" ) {
		cpus = 1
		memory = 4.GB
	}

    input:
    tuple val(meta_sample), val(targets), path(data), path(stats), path(plots)
    
    output:
    tuple val(meta_sample), path("${meta_sample.id}_peak_stats.tsv")

    script:
    """
    head -n 1 ${stats[0]} > "${meta_sample.id}_peak_stats.tsv"
    for STAT in ${stats.join(' ')}; do
        tail -n +2 \$STAT >> "${meta_sample.id}_peak_stats.tsv"
    done
    """

    stub:
	"""
	touch ${meta_sample.id}_peak_stats.tsv
	"""
}