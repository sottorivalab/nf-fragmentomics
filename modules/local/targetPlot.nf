process TARGETPLOT {
    publishDir "${params.outdir}/TIMEPOINTS/fragmentomics/processed/peaks", 
        mode:'copy', 
        overwrite:true

    label 'light_process'

    input:
    tuple val(meta_samples), val(meta_ploidy), val(meta_target), val(meta_ploidy_target), path(peakdata)

    output:
    tuple val(meta_samples), val(meta_ploidy_target), val(meta_target), path("*_peak_plot.pdf")

    script:
    def samples = meta_samples.collect{it['sampleid']}.join(',')
    def prefix = task.ext.prefix ?: "COHORT_${meta_target['name']}_${meta_target['source']}_${meta_ploidy_target['type']}"
    """
    fragmentomics_targetPlots.R ${peakdata.join(' ')} -s ${samples} -o ${prefix}_peak_plot.pdf
    """


    stub:
    def prefix = task.ext.prefix ?: "COHORT_${meta_target[0]['name']}_${meta_target[0]['source']}_${meta_ploidy_target[0]['type']}"
    """
    touch ${prefix}_peak_plot.pdf
    """
}


