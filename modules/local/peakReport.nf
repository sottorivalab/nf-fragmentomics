process PEAK_REPORT {
    debug true
    publishDir "${params.outdir}/${meta_sample.caseid}/${meta_sample.id}/fragmentomics/reports/", mode:'copy', overwrite:true
    label 'local_executor'

    input:
    tuple val(meta_sample), val(meta_targets), path(stats)
    
    output:
    tuple val(meta_sample), path("${meta_sample.id}_all_peaks_stat.tsv")

    script:
    """
    fragmentomics_peakReport.py ${stats.join(' ')} > "${meta_sample.id}_all_peaks_stat.tsv"
    """
    
    stub:
    """
    touch "${meta_sample.id}_all_peaks_stat.tsv"
    """
}