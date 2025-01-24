process PEAK_STATS {
	tag "$meta_sample.sampleid"
	label 'process_medium'

	container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'library://tucano/fragmentomics/fragmentomics_peak_stats:latest' :
        'docker.io/tucano/fragmentomics_peak_stats:latest' }"

    input:
    tuple val(meta_sample), val(meta_target), path(matrix)

    output:
    tuple val(meta_sample), val(meta_target), path("*_peak_data.tsv"), path("*_peak_stats.tsv"), path("*_RawSignal.pdf"),path("*_RelativeSignal.pdf"),path("*_matrix.RDS"),	emit: peaks
	path "versions.yml", emit: versions

    script:
	"""	
	fragmentomics_peakStats.R \\
        -s ${meta_sample.sampleid} \\
        -t ${meta_target.name} \\
        -S ${meta_target.source} \\
        ${matrix}
	
	cat <<-END_VERSIONS > versions.yml
	"${task.process}":
	Rscript: \$(Rscript --version | sed -e "s/Rscript (R) //g")
	END_VERSIONS
	"""

	stub:
	"""
	touch ${meta_sample.sampleid}_${meta_target.name}_${meta_target.source}_peak_data.tsv
	touch ${meta_sample.sampleid}_${meta_target.name}_${meta_target.source}_peak_stats.tsv
	touch ${meta_sample.sampleid}_${meta_target.name}_${meta_target.source}_RawSignal.pdf
	touch ${meta_sample.sampleid}_${meta_target.name}_${meta_target.source}_RelativeSignal.pdf
	touch ${meta_sample.sampleid}_${meta_target.name}_${meta_target.source}_matrix.RDS
	
	cat <<-END_VERSIONS > versions.yml
	"${task.process}":
	Rscript: \$(Rscript --version | sed -e "s/Rscript (R) //g")
	END_VERSIONS
	"""
}