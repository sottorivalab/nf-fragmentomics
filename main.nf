include { COMPUTEGCBIAS } from './modules/local/computeGCbias.nf'
include { CORRECTGCBIAS } from './modules/local/correctGCbias.nf'
include { SAMTOOLSINDEX } from './modules/local/samtoolsIndex.nf'
include { COVERAGEBAM   } from './modules/local/coverageBam.nf'
include { COMPUTEMATRIX } from './modules/local/computeMatrix.nf'
include { HEATMAP       } from './modules/local/heatmap.nf'
include { PEAK_STATS    } from './modules/local/peakStats.nf'
include { PEAK_REPORT   } from './modules/local/peakReport.nf'
include { BIGWIG_MERGE  } from './modules/local/bigWigMerge.nf'

process BWMAPPABILITY {    
	publishDir "${params.outdir}/${meta.caseid}/${meta.id}/fragmentomics/processed/bw", mode:'copy', overwrite:true

    if ( "${workflow.stubRun}" == "false" ) {
		cpus = 1
		memory = 8.GB
	}

    input:
    tuple val(meta), path(bw)

    output:
    tuple val(meta), path("*.mappability_filter.canonical.bw"), emit: bw

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    module load ucsc-tools
    bigWigToBedGraph ${prefix}.bw ${prefix}.bedGraph
    awk '{if (\$1 ~ /^chr/) { print \$1"\t"\$2"\t"\$3"\tid-"NR"\t"\$4; }}' ${prefix}.bedGraph > ${prefix}.bed
    bigWigAverageOverBed ${params.mappability_bw} ${prefix}.bed ${prefix}.mappability.tab
    cut -f 6 ${prefix}.mappability.tab > ${prefix}.mappability_score.out
    paste ${prefix}.bed ${prefix}.mappability_score.out > ${prefix}.mappability.bed
    awk '\$6 >= ${params.mappability_treshold}' ${prefix}.mappability.bed > ${prefix}.mappability_filter.bed
    awk '{printf "%s\\t%d\\t%d\\t%d\\n", \$1,\$2,\$3,\$5}' ${prefix}.mappability_filter.bed > ${prefix}.mappability_filter.bedGraph
    exit 1
    awk '\$1 !~ /_/' ${prefix}.mappability_filter.bedGraph | egrep -v "chrEBV" > ${prefix}.mappability_filter.canonical.bedGraph
    bedGraphToBigWig ${prefix}.mappability_filter.canonical.bedGraph ${params.genome_sizes} ${prefix}.mappability_filter.canonical.bw
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.mappability_filter.canonical.bw
    """
}

workflow {
    // info
    log.info """\
        FRAGMENTOMICS P I P E L I N E    
        ===================================
        outdir       : ${params.outdir}        
        stubRun      : ${workflow.stubRun}
        genome 2bit  : ${params.genome_2bit}
        genome size  : ${params.genome_size}
        chr sizes    : ${params.chr_sizes}
        blacklist    : ${params.blacklist_bed}        
        """
        .stripIndent()

    // samples channel
    sample_ch = Channel.fromPath(params.input)
        .splitCsv(header:true, sep:',')
        .map{ create_sample_channel(it) }
        .dump(tag: 'samples')

    // targets channel
    target_ch = Channel.fromPath(params.targets)
        .splitCsv(header: true, sep:',')
        .map{ create_target_channel(it) }        
        .dump(tag: 'targets')

    COMPUTEGCBIAS(sample_ch)
    sample_with_gc_computed_ch = COMPUTEGCBIAS.out.freqfile       
        .combine(sample_ch, by: 0)
        .dump(tag: 'bam_gc')

    CORRECTGCBIAS(sample_with_gc_computed_ch)    
    SAMTOOLSINDEX(CORRECTGCBIAS.out.gc_correct)
    
    sample_gc_correct_ch = CORRECTGCBIAS.out.gc_correct
        .combine(SAMTOOLSINDEX.out.bai, by: 0)
        .dump(tag: 'bam_with_index')

    COVERAGEBAM(sample_gc_correct_ch)

    // BWMAPPABILITY(COVERAGEBAM.out.bw)

    // combine sample bw and targets
    // target_sample_ch = BWMAPPABILITY.out.bw
    //     .combine(target_ch)
    
    // // merge bw by timepoint
    // timepoint_bw_ch = COVERAGEBAM.out.bw
    //     .map{ sample ->
    //         def tp = sample[0].timepoint
    //         tuple(tp, sample[0], sample[1])
    //     }
    //     .groupTuple(by: 0)
    
    // BIGWIG_MERGE(timepoint_bw_ch)

    // COMPUTEMATRIX(target_sample_ch)    
    // // COMPUTEMATRIX.out.matrix.view()
    // HEATMAP(COMPUTEMATRIX.out.matrix)
    // PEAK_STATS(COMPUTEMATRIX.out.matrix)

    // // collect all peak stats and build a report per sample
    // sample_peaks_ch = PEAK_STATS.out.peak.groupTuple(by:0)        

    // PEAK_REPORT(sample_peaks_ch)

    // buffer example
    // .buffer(size: params.buffer_size, remainder: true)    
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