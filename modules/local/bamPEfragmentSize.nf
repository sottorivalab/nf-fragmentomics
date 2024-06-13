process BAMPEFRAGMENTSIZE {
   
    conda '/home/davide.rambaldi/miniconda3/envs/deeptools'

    publishDir "${params.outdir}/${meta.caseid}/${meta.sampleid}/fragmentomics/reports/", 
        mode:'copy', 
        overwrite:true

    label 'fast_process'

    input:
    tuple val(meta), path(bam), path(bai), path(seg)

    output:
    tuple val(meta), path("*_fragmentsize.png"), path("*_fragmentsize.txt"), emit: bamqc

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${bam.baseName}"
    """
    bamPEFragmentSize \\
        -b ${bam} \\
        -hist ${prefix}_fragmentsize.png \\
        -T "Sample: ${meta.sampleid}" \\
        --numberOfProcessors ${task.cpus} \\
        $args 1>${prefix}_fragmentsize.txt
    """

    stub:
    def prefix = task.ext.prefix ?: "${bam.baseName}"
    """
    touch ${prefix}_fragmentsize.png
    touch ${prefix}_fragmentsize.txt
    """
}