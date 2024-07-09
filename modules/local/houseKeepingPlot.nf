process HOUSEKEEPING_PLOT {

    publishDir "${params.outdir}/${meta.caseid}/${meta.sampleid}/fragmentomics/reports", 
        mode:'copy', 
        overwrite:true

    label 'light_process'

    input:
    tuple val(meta), path(hk), path(rand)

    output:
    tuple val(meta), path("*_signal.pdf")

    script:
    """
    module unload R/rstudio-dependencies
	module load R/4.3.1
    module load nlopt
    fragmentomics_HouseKeepingPlot.R -s ${meta.sampleid}_ALL ${hk} ${rand}
    """

    stub:
    """
    touch ${meta.sampleid}_HouseKeeping_raw_signal.pdf
    touch ${meta.sampleid}_HouseKeeping_relative_signal.pdf
    """
}