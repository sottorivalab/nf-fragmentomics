process SEGTARGETINTERSECT {
    
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bedtools:2.31.1--hf5e1c6e_0' :
        'biocontainers/bedtools:2.31.1--hf5e1c6e_0' }"
        
    publishDir "${params.outdir}/${meta_sample.caseid}/${meta_sample.sampleid}/fragmentomics/processed/targets/${meta_target.source}/${meta_target.name}",
        mode:'copy', 
        overwrite:true

    label "local_executor"

    input:
    tuple val(meta_sample), path(gainbed), path(neutbed), path(lossbed), val(meta_target), path(targets_bed)
    
    output:
    tuple val(meta_sample), val(meta_target), path("*_GAIN.bed"), emit: gain_targets
    tuple val(meta_sample), val(meta_target), path("*_NEUT.bed"), emit: neut_targets
    tuple val(meta_sample), val(meta_target), path("*_LOSS.bed"), emit: loss_targets
    tuple val(meta_sample), val(meta_target), path("*_ALL.bed"),  emit: all_targets

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta_sample.sampleid}_${meta_target.name}_${meta_target.source}"
    """
    bedtools intersect -a $targets_bed -b ${gainbed} -wa > ${prefix}_GAIN.bed
    bedtools intersect -a $targets_bed -b ${neutbed} -wa > ${prefix}_NEUT.bed
    bedtools intersect -a $targets_bed -b ${lossbed} -wa > ${prefix}_LOSS.bed
    cp $targets_bed ${prefix}_ALL.bed
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta_sample.sampleid}_${meta_target.name}_${meta_target.source}"
    """
    touch ${prefix}_GAIN.bed
    touch ${prefix}_NEUT.bed
    touch ${prefix}_LOSS.bed
    touch ${prefix}_ALL.bed
    """
}