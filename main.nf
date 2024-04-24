include { COMPUTEGCBIAS    } from './modules/local/computeGCbias.nf'
include { CORRECTGCBIAS    } from './modules/local/correctGCbias.nf'
include { SAMTOOLSINDEX    } from './modules/local/samtoolsIndex.nf'
include { COVERAGEBAM      } from './modules/local/coverageBam.nf'
include { COMPUTEMATRIX    } from './modules/local/computeMatrix.nf'
include { HEATMAP          } from './modules/local/heatmap.nf'
include { PEAK_STATS       } from './modules/local/peakStats.nf'
include { PEAK_REPORT      } from './modules/local/peakReport.nf'
include { BIGWIG_MERGE     } from './modules/local/bigWigMerge.nf'
include { BEDGRAPHTOBIGWIG } from './modules/local/bedGraphToBigWig.nf'
include { SEG2BED          } from './modules/local/seg2bed.nf'

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

    // combine samples seg and target for GAIN vs NEUT
    seg_ch = sample_ch
        .map{ it ->
            [it[0],it[3]]
        }
    
    SEG2BED(seg_ch)

    // seg_ch = sample_ch
    //     .combine(target_ch)
    //     .map{ it ->
    //         [it[0], it[4], it[3], it[5]]
    //     }
    //     .dump(tag: 'ploidy')
    //     .view()



    // COMPUTEGCBIAS(sample_ch)
    // sample_with_gc_computed_ch = COMPUTEGCBIAS.out.freqfile       
    //     .combine(sample_ch, by: 0)
    //     .dump(tag: 'bam_gc')

    // CORRECTGCBIAS(sample_with_gc_computed_ch)    
    // SAMTOOLSINDEX(CORRECTGCBIAS.out.gc_correct)
    
    // sample_gc_correct_ch = CORRECTGCBIAS.out.gc_correct
    //     .combine(SAMTOOLSINDEX.out.bai, by: 0)
    //     .dump(tag: 'bam_with_index')

    // COVERAGEBAM(sample_gc_correct_ch)

    // // combine sample bw and targets
    // target_sample_ch = COVERAGEBAM.out.bw
    //     .combine(target_ch)
    //     .dump(tag: 'combine')
    
    // COMPUTEMATRIX(target_sample_ch)    
    // HEATMAP(COMPUTEMATRIX.out.matrix)
    // PEAK_STATS(COMPUTEMATRIX.out.matrix)

    // // merge bw by timepoint
    // timepoint_bw_ch = COVERAGEBAM.out.bw
    //     .map{ sample ->
    //         def tp = sample[0].timepoint
    //         tuple(tp, sample[0], sample[1])
    //     }
    //     .groupTuple(by: 0)
    //     .dump(tag: 'timepoints')
    
    // BIGWIG_MERGE(timepoint_bw_ch)
    // BEDGRAPHTOBIGWIG(BIGWIG_MERGE.out.bedgraph)
    
    // // collect all peak stats and build a report per sample    
    // sample_peaks_ch = PEAK_STATS.out.peak
    //     .map { sample ->
    //         def peak_meta = sample[1]
    //         def peak_path = sample[3]
    //         return [
    //             sample[0]['caseid'],
    //             sample[0]['id'], 
    //             peak_meta['name'], 
    //             peak_meta['source'], 
    //             peak_path
    //         ]
    //     }
    //     .groupTuple(by:0)
    //     .dump(tag: 'sample_peaks')

    // // peak report
    // PEAK_REPORT(sample_peaks_ch)
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
    sample = [meta, file(row.bam), file(row.bai), file(row.seg)]
    return sample
}
