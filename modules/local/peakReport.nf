process PEAK_REPORT {
    debug true
    publishDir "${params.outdir}/${meta_sample.caseid}/${meta_sample.id}/fragmentomics/reports/", mode:'copy', overwrite:true

    if ( "${workflow.stubRun}" == "false" ) {
		cpus = 1
		memory = 4.GB
	}

    input:
    tuple val(meta_sample), val(meta_targets), path(stats_all), path(stats_gain), path(stats_neut)
    
    output:
    tuple val(meta_sample), path("${meta_sample.id}_all_peaks_stat.tsv")

    script:
    """
    fragmentomics_peakReport.py ${stats_all.join(' ')} ${stats_gain.join(' ')} ${stats_neut.join(' ')} > "${meta_sample.id}_all_peaks_stat.tsv"
    """
    
    stub:
    """
    touch "${meta_sample.id}_all_peaks_stat.tsv"
    """
}