process BIGWIG_AVERAGE_OVERBED {
    
    label 'normal_process'

    input:
	tuple val(meta_sample), val(meta_ploidy), path(bw), val(meta_target), val(meta_ploidy_target), path(bed)

    output:
	tuple val(meta_sample), val(meta_ploidy), path(bw), val(meta_target), val(meta_ploidy_target), path(bed), path("${bw.baseName}.tab"), emit: bwtab
    
    script:
    def prefix = task.ext.prefix ?: bw.baseName
    """
    module load ucsc-tools
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