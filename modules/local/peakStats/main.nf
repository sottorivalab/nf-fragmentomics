process PEAK_STATS {
    // TODO CONTAINER

	publishDir "${params.outdir}/${meta_sample.caseid}/${meta_sample.sampleid}/fragmentomics/processed/matrix/${meta_target.source}/${meta_target.name}", 
		mode:'copy', 
		overwrite:true

	label 'light_process'
	

    input:
    tuple val(meta_sample), val(meta_target), path(matrix)

    output:
    tuple val(meta_sample), val(meta_target), path("*_peak_data.tsv"), path("*_peak_stats.csv"), path("*_PeakIntegration.pdf"),	emit: peaks

    script:
	"""
	module unload R/rstudio-dependencies
	module load R/4.3.1
    module load nlopt
	fragmentomics_peakStats.R \\
        -s ${meta_sample.sampleid} \\
        -t ${meta_target.name} \\
        -p ${meta_ploidy.type} \\
        -S ${meta_target.source} \\
        ${matrix}
	"""

	stub:
	"""
	touch ${meta_sample.sampleid}_${meta_target.name}_${meta_target.source}_peak_data.tsv
	touch ${meta_sample.sampleid}_${meta_target.name}_${meta_target.source}_peak_stats.csv
	touch ${meta_sample.sampleid}_${meta_target.name}_${meta_target.source}_PeakIntegration.pdf
	"""
}