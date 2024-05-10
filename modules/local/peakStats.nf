process PEAK_STATS {
    publishDir "${params.outdir}/${meta_sample.caseid}/${meta_sample.id}/fragmentomics/processed/matrix/${meta_target.source}/${meta_target.name}", mode:'copy', overwrite:true
	label 'hpc_executor'
	
    if ( "${workflow.stubRun}" == "false" ) {
		cpus = 1
		memory = 4.GB
		time = '1h'
	}

    input:
    tuple val(meta_sample), val(meta_target), path(matrix)

    output:
    tuple val(meta_sample), val(meta_target), path("*_peak_data.tsv"), path("*_peak_stats.tsv"), path("*_PeakIntegration.pdf"),	emit: peaks

    script:
	"""
	module unload R/rstudio-dependencies
	module load R/4.3.1
    module load nlopt
	fragmentomics_peakStats.R ${matrix}
	"""

	stub:
	"""
	touch ${meta_sample.id}_${meta_target.name}_peak_data.tsv
	touch ${meta_sample.id}_${meta_target.name}_peak_stats.tsv
	touch ${meta_sample.id}_${meta_target.name}_PeakIntegration.pdf
	"""
}