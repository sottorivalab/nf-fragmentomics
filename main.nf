
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
include { SAMTOOLSFILTERSEG  } from "./modules/local/samtoolsFilterWithSeg.nf"
include { SAMTOOLSCOUNTREADS } from "./modules/local/samtoolsCountReads.nf"
include { SAMTOOLS_SUBSAMPLE } from "./modules/local/samtoolsSubSample.nf"
include { SAMTOOLSINDEX as SAMTOOLSINDEX_SUBSAMPLE } from './modules/local/samtoolsIndex.nf'

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

    /////////////////////////////////////////////////
    // SAMPLES
    /////////////////////////////////////////////////

    // samples channel
    sample_ch = Channel.fromPath(params.input)
        .splitCsv(header:true, sep:',')
        .map{ create_sample_channel(it) }
        .dump(tag: 'samples')

    // combine samples seg and target for GAIN vs NEUT
    seg_ch = sample_ch
        .map{ it ->
            [it[0],it[3]]
        }
        .dump(tag: 'seqments')

    /////////////////////////////////////////////////
    // TARGETS
    /////////////////////////////////////////////////

    // HouseKeeping genes
    housekeeping_ch = Channel.fromPath(params.housekeeping_bed)
        .map{ it ->
            [['name': 'HouseKeeping', 'source': 'GENEHANCER'], it]
        }
    
    // random TSS
    random_tss_ch = Channel.fromPath(params.random_tss_bed)
        .map{ it ->            
            [['name': it.baseName.replaceFirst(/^.*_/,""), 'source': 'GENEHANCER'], it]
        }

    // targets channel
    target_ch = Channel.fromPath(params.targets)
        .splitCsv(header: true, sep:',')
        .map{ create_target_channel(it) }
        .filter{ it ->
            it[1].size() > 0 
        }
        .concat(housekeeping_ch, random_tss_ch)
        .dump(tag: 'targets')


    // GC CORRECTIONS
    bam_sample_ch = sample_ch
        .map { it ->
            [it[0], it[1], it[2]]
        }
        .dump(tag: 'sample_bams')


    // SEG2BED(seg_ch)

    // target_sample_ploidy_ch = SEG2BED.out.ploidy
    //     .combine(target_ch)
    //     .map{ it ->
    //         [it[0], it[3], it[1], it[2], it[4]]
    //     }
        
    // SEGTARGETINTERSECT(target_sample_ploidy_ch)

    

    // COMPUTEGCBIAS(bam_sample_ch)
    // bam_sample_with_gc_computed_ch = COMPUTEGCBIAS.out.freqfile       
    //     .combine(bam_sample_ch, by: 0)
    //     .dump(tag: 'bam_gc')

    // CORRECTGCBIAS(bam_sample_with_gc_computed_ch)    
    // SAMTOOLSINDEX(CORRECTGCBIAS.out.gc_correct)
    
    // all_targets_ch = SEGTARGETINTERSECT.out.all_targets
    //     .concat(
    //         SEGTARGETINTERSECT.out.gain_targets.filter{ it -> it[2].size() > 0},
    //         SEGTARGETINTERSECT.out.neut_targets.filter{ it -> it[2].size() > 0},
    //     )

    // // TODO extract the same number of reads from GAIN and NEUT wd: same_number_of_reads
    // sample_gc_correct_filter_ploidy = SAMTOOLSINDEX.out.indexed_bam
    //     .combine(SEG2BED.out.ploidy, by: 0)
    //     .dump(tag: 'filtered_bam_ploidy')

    // SAMTOOLSFILTERSEG(sample_gc_correct_filter_ploidy)
    // SAMTOOLSCOUNTREADS(SAMTOOLSFILTERSEG.out.ploidy_bam)
    
    // sample_gc_correct_filter_ploidy_with_counts = SAMTOOLSFILTERSEG.out.ploidy_bam
    //     .combine(SAMTOOLSCOUNTREADS.out.counts, by: 0)
    
    // SAMTOOLS_SUBSAMPLE(sample_gc_correct_filter_ploidy_with_counts)
    // split_subsample_multiMap = SAMTOOLS_SUBSAMPLE.out.subsample
    //     .multiMap{ it ->
    //         neut: [it[0], it[1]]
    //         gain: [it[0], it[2]]
    //     }

    // split_subsample_ch = split_subsample_multiMap.neut
    //     .concat(split_subsample_multiMap.gain)
    
    // SAMTOOLSINDEX_SUBSAMPLE(split_subsample_ch)
    
    // all_sample_bams_ch = SAMTOOLSINDEX.out.indexed_bam
    //     .concat(SAMTOOLSINDEX_SUBSAMPLE.out.indexed_bam)
    //     .dump(tag: 'all_sample_bams')

    // COVERAGEBAM(all_sample_bams_ch)
    
    // // combine sample bw and ploidy targets
    // ploidy_target_sample_ch = COVERAGEBAM.out.bw
    //     .combine(all_targets_ch, by: 0)
    //     .map{ it ->
    //         [it[0], it[2], it[1], it[3]]
    //     }
    //     .dump(tag: 'ploidy_targets')
    
    // // TODO add TSS HouseKeeping targets and random sets
    // COMPUTEMATRIX(ploidy_target_sample_ch)
    // HEATMAP(COMPUTEMATRIX.out.matrix)
    // PEAK_STATS(COMPUTEMATRIX.out.matrix)

    // // collect all peak stats and build a report per sample  
    // sample_peaks_ch = PEAK_STATS.out.peaks
    //     .map{ it -> 
    //         return [
    //             it[0],
    //             it[1],
    //             it[3]
    //         ]
    //     }        
    //     .groupTuple(by: 0)
    //     .dump(tag: 'sample_peaks')

    // peak report
    // PEAK_REPORT(sample_peaks_ch)

    // merge bw by timepoint only when we have more than one sample
    // if (file(params.input).countLines() > 2) {
    //     timepoint_bw_ch = COVERAGEBAM.out.bw
    //         .map{ sample ->
    //             def tp = sample[0].timepoint
    //             tuple(tp, sample[0], sample[1])
    //         }
    //         .groupTuple()
    //         .dump(tag: 'timepoints')        
    //     BIGWIG_MERGE(timepoint_bw_ch)
    //     BEDGRAPHTOBIGWIG(BIGWIG_MERGE.out.bedgraph)
    // }
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
