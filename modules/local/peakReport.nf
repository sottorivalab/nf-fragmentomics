process PEAK_REPORT {
    publishDir "${params.outdir}/${meta_sample.caseid}/${meta_sample.id}/fragmentomics/reports/", mode:'copy', overwrite:true

    if ( "${workflow.stubRun}" == "false" ) {
		cpus = 1
		memory = 4.GB
	}

    input:
    tuple val(meta_sample), val(targets), path(data), path(stats), path(plots)
    
    output:
    tuple val(meta_sample), path("${meta_sample.id}_all_peaks_stat.tsv")

    script:
    """
    echo -e "target\tintegration\tlength\tymin\tymax\tx\tratio" > "${meta_sample.id}_all_peaks_stat.tsv"
    for STAT in ${stats.join(' ')}; do
        mdata=`tail -n +2 \$STAT`
        mtarget=`basename \$STAT _peak_stats.tsv | sed 's/${meta_sample.id}_//'`
        echo -e "\$mtarget\t\$mdata" >> "${meta_sample.id}_all_peaks_stat.tsv"
    done
    """

    stub:
	"""
	touch ${meta_sample.id}_all_peaks_stat.tsv
	"""
}