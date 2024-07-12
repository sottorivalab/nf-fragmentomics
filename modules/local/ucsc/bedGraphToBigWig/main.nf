process BEDGRAPHTOBIGWIG {

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ucsc-bedgraphtobigwig:445--h954228d_0' :
        'biocontainers/ucsc-bedgraphtobigwig:445--h954228d_0' }"
        
    publishDir "${params.outdir}/TIMEPOINTS/fragmentomics/processed/bw/${ploidy}", 
        mode:'copy', 
        overwrite:true
                
    label 'heavy_process'
    
    input:
    tuple val(timepoint), val(ploidy), path(bedgraph), path(chr_sizes)

    output:
    tuple val(timepoint), val(ploidy), path("*.bw"), emit: bw

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "COHORT_${timepoint}_${ploidy}"
    """
    sort -k1,1 -k2,2n ${bedgraph} > sorted.bg
    bedGraphToBigWig sorted.bg ${chr_sizes} ${prefix}.bw 
    """

    stub:
    def prefix = task.ext.prefix ?: "COHORT_${timepoint}_${ploidy}"
    """
    touch ${prefix}.bw
    """
}