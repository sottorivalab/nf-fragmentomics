process PEAK_REPORT {
    debug true
    publishDir "${params.outdir}/${caseid}/${sampleid[0]}/fragmentomics/reports/", mode:'copy', overwrite:true

    if ( "${workflow.stubRun}" == "false" ) {
		cpus = 1
		memory = 4.GB
	}

    input:
    tuple val(caseid), val(sampleid), val(targets), val(sources), path(stats)
    
    output:
    path("${sampleid[0]}_all_peaks_stat.tsv")

    script:
    def target_data = "name,source,path\n"
    for (int i=0; i<targets.size(); i++) {
        target_data += "${targets[i]},${sources[i]},${stats[i]}\n"
    }
    
    """
    cat <<EOT >> targets.csv
${target_data}
EOT
    fragmentomics_peakReport.py targets.csv > ${sampleid[0]}_all_peaks_stat.tsv
    """

    stub:
	"""
	touch ${sampleid[0]}_all_peaks_stat.tsv
	"""
}