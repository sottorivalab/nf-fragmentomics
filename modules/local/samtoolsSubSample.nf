process SAMTOOLS_SUBSAMPLE {
    publishDir "${params.outdir}/${sample.caseid}/${sample.id}/fragmentomics/processed/bam", mode:'copy', overwrite:true
    label "hpc_executor"
    debug true
    
    if ( "${workflow.stubRun}" == "false" ) {
		cpus = 4
		memory = 16.GB
		time = '4h'
	}
    
    input:
    tuple val(sample), path(neutbam), path(gainbam), path(table)

    output:
    tuple val(sample), path("*NEUT.subsample.bam"), path("*GAIN.subsample.bam"), emit: subsample

    script:
    """
    module load samtools
    fragmentomics_subSample.py --cpu ${task.cpus} ${neutbam} ${gainbam} ${table}
    """

    stub:
    """
    touch ${neutbam.baseName}.subsample.bam
    touch ${gainbam.baseName}.subsample.bam
    """
}