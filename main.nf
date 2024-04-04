process COMPUTEGCBIAS {
    conda '/home/davide.rambaldi/miniconda3/envs/deeptools'
	publishDir "${params.outdir}/${meta.caseid}/${meta.id}/fragmentomics/processed/bam", mode:'copy', overwrite:true

    if ( "${workflow.stubRun}" == "false" ) {
		cpus = 32
		memory = 128.GB
	}
	
	input:
	tuple val(meta), file(bam), file(bai)

	output:
	tuple val(meta), path("*.freq.txt"), emit: freqfile

	script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
	"""
	computeGCBias \\
        -b ${bam} \\
        --effectiveGenomeSize ${params.genome_size} \\
        -g ${params.genome} \\
        --GCbiasFrequenciesFile ${prefix}.freq.txt \\
        --numberOfProcessors ${task.cpus} \\
        $args
	"""

	stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
	"""
	touch ${prefix}.freq.txt
	"""
}

process CORRECTGCBIAS {
    conda '/home/davide.rambaldi/miniconda3/envs/deeptools'
	publishDir "${params.outdir}/${meta.caseid}/${meta.id}/fragmentomics/processed/bam", mode:'copy', overwrite:true

    if ( "${workflow.stubRun}" == "false" ) {
		cpus = 32
		memory = 256.GB
	}

    input:
	tuple val(meta), path(freq), path(bai), path(bam)

	output:
	tuple val(meta), path("*.gc_correct.bam"), emit: gc_correct

	script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
	"""
	correctGCBias \\
        -b $bam \\
        --effectiveGenomeSize ${params.genome_size} \\
        -g ${params.genome} \\
        --GCbiasFrequenciesFile $freq \\
        --numberOfProcessors ${task.cpus} \\
        -o ${prefix}.gc_correct.bam \\
        $args
	"""

	stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
	"""
	touch ${prefix}.gc_correct.bam
	"""
}

process SAMTOOLSINDEX {
	publishDir "${params.outdir}/${meta.caseid}/${meta.id}/fragmentomics/processed/bam", mode:'copy', overwrite:true

	if ( "${workflow.stubRun}" == "false" ) {
		cpus = 4
		memory = 16.GB
	}
	
	input:
	tuple val(meta), path(bam)

	output:
	tuple val(meta), path("*.bai"), emit: bai
	
	script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
	"""
	module load samtools
	samtools index -@ ${task.cpus} $bam $args
	"""

	stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
	"""
	touch ${prefix}.gc_correct.bam.bai
	"""
	
}

process COVERAGEBAM {
	conda '/home/davide.rambaldi/miniconda3/envs/deeptools'
	publishDir "${params.outdir}/${meta.caseid}/${meta.id}/fragmentomics/processed/bw", mode:'copy', overwrite:true

	if ( "${workflow.stubRun}" == "false" ) {
		cpus = 32
		memory = 128.GB
	}

	input:
	tuple val(meta), path(bam), path(bai)
	
	output:
	tuple val(meta), path("*.bw"), emit: bw

	script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
	"""
	bamCoverage -b $bam -o ${prefix}.bw --numberOfProcessors ${task.cpus} $args
	"""

	stub:    
    def prefix = task.ext.prefix ?: "${meta.id}"
	"""
	touch "${prefix}.bw"
	"""
}

process COMPUTEMATRIX {
	conda '/home/davide.rambaldi/miniconda3/envs/deeptools'
    publishDir "${params.outdir}/${meta_sample.caseid}/${meta_sample.id}/fragmentomics/processed/matrix/${meta_target.source}/${meta_target.name}", mode:'copy', overwrite:true	

	if ( "${workflow.stubRun}" == "false" ) {
		cpus = 32
		memory = 128.GB
	}
	
	input:
	tuple val(meta_sample), path(bw), val(meta_target), path(bed)
	
	output:
	tuple val(meta_sample), val(meta_target), path("${meta_sample.id}_${meta_target.name}_matrix.gz"), emit: matrix

	script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta_sample.id}_${meta_target.name}"
	"""
	computeMatrix reference-point \\
        --referencePoint center \\
        -S $bw \\
        -R $bed \\
        -a 4000 \\
        -b 4000 \\
        -o ${prefix}_matrix.gz \\
        --numberOfProcessors ${task.cpus} \\
        $args
	"""

	stub:
    def prefix = task.ext.prefix ?: "${meta_sample.id}_${meta_target.name}"
	"""
	touch ${prefix}_matrix.gz
	"""
}

process HEATMAP {
    conda '/home/davide.rambaldi/miniconda3/envs/deeptools'
    publishDir "${params.outdir}/${meta_sample.caseid}/${meta_sample.id}/fragmentomics/reports/heatmaps", mode:'copy', overwrite:true
    

    input:
    tuple val(meta_sample), val(meta_targets), path(matrixes)

    script:    
    """
    """

    stub:
    """
    for MATRIX in ${matrix_data}; do
        echo \${MATRIX}
    done    
    """
}


workflow {
    // info
    log.info """\
        FRAGMENTOMICS P I P E L I N E    
        ===================================
        genome       : ${params.genome}
        genome size  : ${params.genome_size}
        outdir       : ${params.outdir}
        buffer size  : ${params.buffer_size}
        stubRun      : ${workflow.stubRun}
        """
        .stripIndent()

    // samples channel
    sample_ch = Channel.fromPath(params.input)
        .splitCsv(header:true, sep:',')
        .map{ create_sample_channel(it) }

    // targets channel
    target_ch = Channel.fromPath(params.targets)
        .splitCsv(header: true, sep:',')
        .map{ create_target_channel(it) }        

    COMPUTEGCBIAS(sample_ch)
    sample_with_gc_computed_ch = COMPUTEGCBIAS.out.freqfile       
        .combine(sample_ch, by: 0)
    
    CORRECTGCBIAS(sample_with_gc_computed_ch)    
    SAMTOOLSINDEX(CORRECTGCBIAS.out.gc_correct)
    
    sample_gc_correct_ch = CORRECTGCBIAS.out.gc_correct
        .combine(SAMTOOLSINDEX.out.bai, by: 0)

    COVERAGEBAM(sample_gc_correct_ch)

    target_sample_ch = COVERAGEBAM.out.bw
        .combine(target_ch)
    
    COMPUTEMATRIX(target_sample_ch)
    
    // group by sample and source
    matrix_ch = COMPUTEMATRIX.out.matrix
        .map { 
            return tuple(
                tuple(it[0].caseid, it[0].id, it[0].timepoint, it[1].source),
                it[1],
                it[2]
            )
        }
        .groupTuple(by: 0)
        .view()


    // buffer example
    // .buffer(size: params.buffer_size, remainder: true)

    // HEATMAP(heatmap_ch)
}

def create_target_channel(LinkedHashMap row) {
    def meta = [:]
    meta.name = row.name
    meta.source = row.source
    def target = []
    target = [meta, row.bed]
    return target
}

def create_sample_channel(LinkedHashMap row) {
    // create all at once
    def meta = [:]
    meta.caseid = row.caseid
    meta.id = row.sampleid
    meta.timepoint = row.timepoint

    def sample = []
    sample = [meta, file(row.bam), file(row.bai)]
    return sample
}