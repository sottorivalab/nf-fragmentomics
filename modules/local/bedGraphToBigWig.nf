process BEDGRAPHTOBIGWIG {
    publishDir "${params.outdir}/TIMEPOINTS/processed/bw", 
        mode:'copy', 
        overwrite:true
                
    label 'heavy_process'
    
    if ( "${workflow.stubRun}" == "false" ) {
		cpus = 1
		memory = 24.GB
        time = '8h'
	}

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