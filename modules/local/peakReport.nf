process PEAK_REPORT {
    
    publishDir "${params.outdir}/${meta_sample.caseid}/${meta_sample.sampleid}/fragmentomics/reports/", 
        mode:'copy', 
        overwrite:true
    
    label 'light_process'

    input:
    tuple val(meta_sample), val(meta_ploidy), val(meta_target), val(meta_ploidy_target), path(stats)
    
    output:
    tuple val(meta_sample), path("*_all_peaks_stat.tsv")

    script:
    """
    fragmentomics_peakReport.py ${stats.join(' ')} > "${meta_sample.sampleid}_all_peaks_stat.tsv"
    """
    
    stub:
    """
    touch "${meta_sample.sampleid}_all_peaks_stat.tsv"
    """
}