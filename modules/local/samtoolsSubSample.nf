process SAMTOOLS_SUBSAMPLE {
    publishDir "${params.outdir}/${sample.caseid}/${sample.id}/fragmentomics/processed/bam", mode:'copy', overwrite:true
    label "hpc_executor"
    debug true
    
    if ( "${workflow.stubRun}" == "false" ) {
		cpus = 4
		memory = 16.GB
		time = '2h'
	}
    
    input:
    tuple val(sample), path(neutbam), path(gainbam), path(table)

    // output:
    // tuple val(meta)

    script:
    """
    """

    stub:
    """
    """
}