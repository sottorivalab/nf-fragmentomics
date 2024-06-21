process BEDGRAPHTOBIGWIG {

    publishDir "${params.outdir}/TIMEPOINTS/fragmentomics/processed/bw/${ploidy}", 
        mode:'copy', 
        overwrite:true
                
    label 'heavy_process'
    
    input:
    tuple val(timepoint), val(ploidy), path(bedgraph)

    output:
    tuple val(timepoint), val(ploidy), path("*.bw"), emit: bw

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "COHORT_${timepoint}_${ploidy}"
    """
    module load ucsc-tools
    bedGraphToBigWig ${bedgraph} ${params.chr_sizes} ${prefix}.bw 
    """

    stub:
    def prefix = task.ext.prefix ?: "COHORT_${timepoint}_${ploidy}"
    """
    touch ${prefix}.bw
    """
}