process SEGTARGETINTERSECT {
    
    publishDir "${params.outdir}/${meta_sample.caseid}/${meta_sample.sampleid}/fragmentomics/processed/targets/${meta_target.source}/${meta_target.name}",
        mode:'copy', 
        pattern: "*.bed",
        overwrite:true

    label "local_executor"

    input:
    tuple val(meta_sample), path(gainbed), path(neutbed), val(meta_target), path(targets_bed)
    
    output:
    tuple val(meta_sample), val(meta_target), path("*_GAIN.bed"), emit: gain_targets
    tuple val(meta_sample), val(meta_target), path("*_NEUT.bed"), emit: neut_targets
    tuple val(meta_sample), pval(meta_target), path("*_ALL.bed"),  emit: all_targets

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta_sample.sampleid}_${meta_target.name}_${meta_target.source}"
    """
    module load bedtools2
    bedtools intersect -a $targets_bed -b ${gainbed} -wa > ${prefix}_GAIN.bed
    bedtools intersect -a $targets_bed -b $neutbed -wa > ${prefix}_NEUT.bed
    cp $targets_bed ${prefix}_ALL.bed
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta_sample.sampleid}_${meta_target.name}_${meta_target.source}"
    """
    touch ${prefix}_GAIN.bed
    touch ${prefix}_NEUT.bed
    touch ${prefix}_ALL.bed
    """
}