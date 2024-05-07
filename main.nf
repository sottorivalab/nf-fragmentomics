include { COMPUTEGCBIAS      } from './modules/local/computeGCbias.nf'
include { CORRECTGCBIAS      } from './modules/local/correctGCbias.nf'
include { SAMTOOLSINDEX      } from './modules/local/samtoolsIndex.nf'
include { COVERAGEBAM        } from './modules/local/coverageBam.nf'
include { COMPUTEMATRIX      } from './modules/local/computeMatrix.nf'
include { HEATMAP            } from './modules/local/heatmap.nf'
include { PEAK_STATS         } from './modules/local/peakStats.nf'
include { PEAK_REPORT        } from './modules/local/peakReport.nf'
include { BIGWIG_MERGE       } from './modules/local/bigWigMerge.nf'
include { BEDGRAPHTOBIGWIG   } from './modules/local/bedGraphToBigWig.nf'
include { SEG2BED            } from './modules/local/seg2bed.nf'
include { SEGTARGETINTERSECT } from './modules/local/segTargetIntersect.nf'

workflow {
    // info
    log.info """\
        ===================================
        FRAGMENTOMICS P I P E L I N E    
        ===================================
        input         : ${params.input}
        targets       : ${params.targets}
        outdir        : ${params.outdir}        
        stubRun       : ${workflow.stubRun}
        genome 2bit   : ${params.genome_2bit}
        genome size   : ${params.genome_size}
        chr sizes     : ${params.chr_sizes}
        blacklist     : ${params.blacklist_bed}
        target expand : ${params.target_expand_sx} bp - ${params.target_expand_dx} bp
        ===================================
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
        .filter{ it ->
            it[1].size() > 0 
        }
        .dump(tag: 'targets')

    // combine samples seg and target for GAIN vs NEUT
    seg_ch = sample_ch
        .map{ it ->
            [it[0],it[3]]
        }
    
    SEG2BED(seg_ch)

    target_sample_ploidy_ch = SEG2BED.out.ploidy
        .combine(target_ch)
        .map{ it ->
            [it[0], it[3], it[1], it[2], it[4]]
        }

    SEGTARGETINTERSECT(target_sample_ploidy_ch)

    bam_sample_ch = sample_ch
        .map { it ->
            [it[0], it[1], it[2]]
        }

    COMPUTEGCBIAS(bam_sample_ch)
    bam_sample_with_gc_computed_ch = COMPUTEGCBIAS.out.freqfile       
        .combine(bam_sample_ch, by: 0)
        .dump(tag: 'bam_gc')

    CORRECTGCBIAS(bam_sample_with_gc_computed_ch)    
    SAMTOOLSINDEX(CORRECTGCBIAS.out.gc_correct)
    
    sample_gc_correct_ch = CORRECTGCBIAS.out.gc_correct
        .combine(SAMTOOLSINDEX.out.bai, by: 0)
        .dump(tag: 'bam_with_index')

    COVERAGEBAM(sample_gc_correct_ch)
    
    // combine sample bw and ploidy targets
    ploidy_target_sample_ch = COVERAGEBAM.out.bw
        .combine(SEGTARGETINTERSECT.out.targets_ploidy, by: 0)
        .map{ it ->
            [it[0], it[2], it[1], it[3], it[4], it[5]]
        }
        .dump(tag: 'ploidy_targets')
    
    // TODO add TSS HouseKeeping targets and random sets

    // we should filter out empty targets
    COMPUTEMATRIX(ploidy_target_sample_ch)

    HEATMAP(COMPUTEMATRIX.out.matrix)
    PEAK_STATS(COMPUTEMATRIX.out.matrix)

    // collect all peak stats and build a report per sample    
    sample_peaks_ch = PEAK_STATS.out.peaks
        .map{ it -> 
            return [
                it[0],
                it[1],
                it[3],
                it[6],
                it[9]
            ]
        }        
        .groupTuple(by: [0])
        .dump(tag: 'sample_peaks')

    // peak report
    PEAK_REPORT(sample_peaks_ch)

    // merge bw by timepoint only when we have more than one sample
    if (file(params.input).countLines() > 2) {
        timepoint_bw_ch = COVERAGEBAM.out.bw
            .map{ sample ->
                def tp = sample[0].timepoint
                tuple(tp, sample[0], sample[1])
            }
            .groupTuple()
            .dump(tag: 'timepoints')        
        BIGWIG_MERGE(timepoint_bw_ch)
        BEDGRAPHTOBIGWIG(BIGWIG_MERGE.out.bedgraph)
    }
    
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
