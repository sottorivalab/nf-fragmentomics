process SAMTOOLSCOUNTREADS {
    publishDir "${params.outdir}/${sample.caseid}/${sample.id}/fragmentomics/processed/bam", mode:'copy', overwrite:true
    label "hpc_executor"

     if ( "${workflow.stubRun}" == "false" ) {
		cpus = 4
		memory = 16.GB
		time = '4h'
	}

    input:
    tuple val(sample), path(neutbam), path(gainbam)

    output:
    tuple val(sample), path("*.csv"), emit: counts

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${sample.id}"
    """
    module load samtools
    NEUT=`samtools view -c ${neutbam}`
    GAIN=`samtools view -c ${gainbam}`
    echo -e "${neutbam.baseName},\$NEUT\n${gainbam.baseName},\$GAIN\n" > ${prefix}.reads.csv
    """

    stub:
    def prefix = task.ext.prefix ?: "${sample.id}"
	"""
	touch ${prefix}.reads.csv
	"""
}