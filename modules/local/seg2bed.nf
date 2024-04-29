process SEG2BED {
    publishDir "${params.outdir}/${sample.caseid}/${sample.id}/fragmentomics/processed/ploidy", mode:'copy', overwrite:true

    if ( "${workflow.stubRun}" == "false" ) {
		cpus = 1
		memory = 4.GB
	}

    input:
    tuple val(sample), path(seg)

    output:
    tuple val(sample), path("${sample.id}_GAIN.bed"), path("${sample.id}_NEUT.bed"), emit: ploidy

    script:
    def args = task.ext.args ?: ''
    """
    fragmentomics_seg2bed.py $seg $args
    """

    stub:
    """
    touch ${sample.id}_NEUT.bed
    touch ${sample.id}_GAIN.bed
    """
}