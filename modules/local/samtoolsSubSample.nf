process SAMTOOLS_SUBSAMPLE {
    label "heavy_process"
    
    input:
    tuple val(meta), path(gainbam), path(neutbam), path(table)

    output:
    tuple val(meta), path("${gainbam.baseName}.subsample.bam"), path("${neutbam.baseName}.subsample.bam"), emit: subsample_bam

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