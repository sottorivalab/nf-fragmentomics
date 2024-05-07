process PEAK_STATS {
    publishDir "${params.outdir}/${meta_sample.caseid}/${meta_sample.id}/fragmentomics/processed/matrix/${meta_target.source}/${meta_target.name}", mode:'copy', overwrite:true

    if ( "${workflow.stubRun}" == "false" ) {
		cpus = 1
		memory = 4.GB
		time = '1h'
	}

    input:
    tuple val(meta_sample), val(meta_target), path(matrix_all), path(matrix_gain), path(matrix_neut)

    output:
    tuple val(meta_sample), 
	val(meta_target), 
	path("*ALL_peak_data.tsv"), 
	path("*ALL_peak_stats.tsv"), 
	path("*ALL_PeakIntegration.pdf"), 
	path("*GAIN_peak_data.tsv"), 
	path("*GAIN_peak_stats.tsv"), 
	path("*GAIN_PeakIntegration.pdf"), 
	path("*NEUT_peak_data.tsv"), 
	path("*NEUT_peak_stats.tsv"), 
	path("*NEUT_PeakIntegration.pdf"), 
	emit: peaks

    script:
	"""
	module unload R/rstudio-dependencies
	module load R/4.3.1
    module load nlopt
	fragmentomics_peakStats.R ${matrix_all}
	fragmentomics_peakStats.R ${matrix_gain}
	fragmentomics_peakStats.R ${matrix_neut}
	"""

	stub:
	"""
	touch ${meta_sample.id}_${meta_target.name}_ALL_peak_data.tsv
	touch ${meta_sample.id}_${meta_target.name}_ALL_peak_stats.tsv
	touch ${meta_sample.id}_${meta_target.name}_ALL_PeakIntegration.pdf
	touch ${meta_sample.id}_${meta_target.name}_GAIN_peak_data.tsv
	touch ${meta_sample.id}_${meta_target.name}_GAIN_peak_stats.tsv
	touch ${meta_sample.id}_${meta_target.name}_GAIN_PeakIntegration.pdf
	touch ${meta_sample.id}_${meta_target.name}_NEUT_peak_data.tsv
	touch ${meta_sample.id}_${meta_target.name}_NEUT_peak_stats.tsv
	touch ${meta_sample.id}_${meta_target.name}_NEUT_PeakIntegration.pdf
	"""
}