process PEAK_STATS {
    
	publishDir "${params.outdir}/${meta_sample.caseid}/${meta_sample.sampleid}/fragmentomics/processed/matrix/${meta_target.source}/${meta_target.name}/${meta_ploidy.type}", 
		mode:'copy', 
		overwrite:true

	label 'light_process'
	

    input:
    tuple val(meta_sample), val(meta_ploidy), val(meta_target), val(meta_ploidy_target), path(matrix)

    output:
    tuple val(meta_sample), val(meta_ploidy), val(meta_target), val(meta_ploidy_target), path("*_peak_data.tsv"), path("*_peak_stats.tsv"), path("*_PeakIntegration.pdf"),	emit: peaks

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