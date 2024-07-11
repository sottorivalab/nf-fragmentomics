process BIGWIG_MERGE {    
    
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ucsc-bigwigmerge%3A377--h446ed27_1' :
        'biocontainers/ucsc-bigwigmerge%3A377--h446ed27_1' }"

    publishDir "${params.outdir}/TIMEPOINTS/fragmentomics/processed/bedgraph/${ploidy}", 
        mode:'copy', 
        overwrite:true
        
    label 'heavy_process'
    
    input:
    tuple val(timepoint), val(ploidy), val(meta_sample), path(bws)

    output:
    tuple val(timepoint), val(ploidy), path("COHORT_${timepoint}_${ploidy}.bedGraph"), emit: bedgraph

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "COHORT_${timepoint}_${ploidy}"
    """
    bigWigMerge ${bws.join(' ')} ${prefix}.bedGraph
    """

    stub:
    def prefix = task.ext.prefix ?: "COHORT_${timepoint}_${ploidy}"
    """
    touch ${prefix}.bedGraph
    """
}