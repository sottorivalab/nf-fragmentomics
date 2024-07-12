process BIGWIG_AVERAGE_OVERBED {
    
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ucsc-bigwigaverageoverbed:377--h0b8a92a_2' :
        'biocontainers/ucsc-bigwigaverageoverbed:377--h0b8a92a_2' }"
        
    label 'normal_process'

    input:
	tuple val(meta_sample), val(meta_ploidy), path(bw), val(meta_target), val(meta_ploidy_target), path(bed)

    output:
	tuple val(meta_sample), val(meta_ploidy), path(bw), val(meta_target), val(meta_ploidy_target), path(bed), path("${bw.baseName}.tab"), emit: bwtab
    
    script:
    def prefix = task.ext.prefix ?: bw.baseName
    """
    awk -F "\t" '{print \$1"\t"\$2"\t"\$3"\t"NR}' ${bed} > ${prefix}_regions.bed
    bigWigAverageOverBed ${bw} ${prefix}_regions.bed ${prefix}.tab
    """

    stub:
    def prefix = task.ext.prefix ?: bw.baseName
    """
    touch ${prefix}_regions.bed
    touch ${prefix}.tab
    """
}