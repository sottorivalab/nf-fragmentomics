process PEAK_STATS {
	tag "$meta_sample.sampleid"
	label 'process_single'

	container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'library://tucano/fragmentomics/fragmentomics_peak_stats:latest' :
        'docker.io/tucano/fragmentomics_peak_stats:latest' }"

    input:
    tuple val(meta_sample), val(source), path(matrix)

    output:
    tuple val(meta_sample), val(source), path("*_peak_data.tsv"), path("*_peak_stats.tsv"), path("*_RawSignal.pdf"), path("*_RelativeSignal.pdf"), emit: peaks
	path "versions.yml", emit: versions

    script:
	"""
	for MAT in ${matrix.join(' ')}; do
		BASENAME=\$(basename \${MAT} _matrix.gz)
		OUTPUT_FILE=\${BASENAME}_peak_data.tsv
		OUTPUT_FILE2=\${BASENAME}_peak_stats.tsv
		OUTPUT_FILE3=\${BASENAME}_RawSignal.pdf
		OUTPUT_FILE4=\${BASENAME}_RelativeSignal.pdf
		
		fragmentomics_peakStats.R \\
			-s ${meta_sample.sampleid} \\
			-t \${BASENAME} \\
			-S ${source} \\
			\${MAT}
	done
	
	cat <<-END_VERSIONS > versions.yml
	"${task.process}":
	Rscript: \$(Rscript --version | sed -e "s/Rscript (R) //g")
	END_VERSIONS
	"""

	stub:
	"""
	for MAT in ${matrix.join(' ')}; do
		BASENAME=\$(basename \${MAT} _matrix.gz)
		OUTPUT_FILE=\${BASENAME}_peak_data.tsv
		OUTPUT_FILE2=\${BASENAME}_peak_stats.tsv
		OUTPUT_FILE3=\${BASENAME}_RawSignal.pdf
		OUTPUT_FILE4=\${BASENAME}_RelativeSignal.pdf
		touch \${OUTPUT_FILE}
		touch \${OUTPUT_FILE2}
		touch \${OUTPUT_FILE3}
		touch \${OUTPUT_FILE4}
	done

	cat <<-END_VERSIONS > versions.yml
	"${task.process}":
	Rscript: \$(Rscript --version | sed -e "s/Rscript (R) //g")
	END_VERSIONS
	"""
}