process SEGTARGETINTERSECT {
    publishDir "${params.outdir}/${meta_sample.caseid}/${meta_sample.id}/fragmentomics/processed/matrix/${meta_target.source}/${meta_target.name}/targets", mode:'copy', overwrite:true

    if ( "${workflow.stubRun}" == "false" ) {
		cpus = 1
		memory = 16.GB
        time = '1h'
	}

    input:
    tuple val(meta_sample), val(meta_target), path(gainseg), path(neutseg), path(targets)
    
    output:
    tuple val(meta_sample), val(meta_target), path("*_GAIN.bed"), path("*_NEUT.bed"), path("*_ALL.bed"), emit: targets_ploidy

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta_sample.id}_${meta_target.name}_${meta_target.source}"
    """
    module load bedtools2
    bedtools intersect -a $targets -b $gainseg -wa > ${prefix}_GAIN.bed
    bedtools intersect -a $targets -b $neutseg -wa > ${prefix}_NEUT.bed
    cp $targets ${prefix}_ALL.bed
    """

    stub:
    """
    touch ${prefix}_GAIN.bed
    touch ${prefix}_NEUT.bed
    touch ${prefix}_ALL.bed
    """
}