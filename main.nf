include { COMPUTEGCBIAS } from './modules/local/computeGCbias.nf'
include { CORRECTGCBIAS } from './modules/local/correctGCbias.nf'
include { SAMTOOLSINDEX } from './modules/local/samtoolsIndex.nf'
include { COVERAGEBAM   } from './modules/local/coverageBam.nf'
include { COMPUTEMATRIX } from './modules/local/computeMatrix.nf'
include { HEATMAP       } from './modules/local/heatmap.nf'
include { PEAK_STATS    } from './modules/local/peakStats.nf'
include { PEAK_REPORT   } from './modules/local/peakReport.nf'
include { BIGWIG_MERGE  } from './modules/local/bigWigMerge.nf'

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

    // combine sample bw and targets
    target_sample_ch = COVERAGEBAM.out.bw
        .combine(target_ch)
        .dump(tag: 'combine')
    
    // merge bw by timepoint
    timepoint_bw_ch = COVERAGEBAM.out.bw
        .map{ sample ->
            def tp = sample[0].timepoint
            tuple(tp, sample[0], sample[1])
        }
        .groupTuple(by: 0)
        .dump(tag: 'timepoints')
    
    BIGWIG_MERGE(timepoint_bw_ch)

    COMPUTEMATRIX(target_sample_ch)    
    HEATMAP(COMPUTEMATRIX.out.matrix)
    PEAK_STATS(COMPUTEMATRIX.out.matrix)

    // collect all peak stats and build a report per sample
    sample_peaks_ch = PEAK_STATS.out.peak.groupTuple(by:0)        
    PEAK_REPORT(sample_peaks_ch)
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