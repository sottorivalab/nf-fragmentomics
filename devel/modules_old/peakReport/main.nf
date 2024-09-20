process PEAK_REPORT {
    
    conda "conda-forge::python=3.8.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.8.3' :
        'biocontainers/python:3.8.3' }"
        
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