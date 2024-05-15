
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
include { SAMTOOLSFILTERSEG  } from "./modules/local/samtoolsFilterSeg.nf"
include { SAMTOOLSCOUNTREADS } from "./modules/local/samtoolsCountReads.nf"
include { SAMTOOLS_SUBSAMPLE } from "./modules/local/samtoolsSubSample.nf"

def create_target_channel(LinkedHashMap row) {
    def meta = [
        name: row.name,
        source: row.source
    ]
    
    def target = []
    target = [meta, row.bed]
    return target
}

def create_sample_channel(LinkedHashMap row) {
    // create all at once
    def meta = [
        caseid: row.caseid,
        sampleid: row.sampleid,
        timepoint: row.timepoint
    ]

    def sample = []
    sample = [meta, file(row.bam), file(row.bai), file(row.seg)]
    return sample
}

workflow {
    /////////////////////////////////////////////////
    // PIPELINE INFO
    /////////////////////////////////////////////////
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
    // SAMPLES meta: [ caseid, sampleid, timepoint ]
    /////////////////////////////////////////////////

    // samples channel
    sample_ch = Channel.fromPath(params.input)
        .splitCsv(header:true, sep:',')
        .map{ create_sample_channel(it) }
        .dump(tag: 'samples')

    /////////////////////////////////////////////////
    // TARGETS meta: [ name, source ]
    /////////////////////////////////////////////////

    // HouseKeeping genes
    housekeeping_ch = Channel.fromPath(params.housekeeping_bed)
        .map{ it ->
            [ ['name': 'HouseKeeping', 'source': 'GENEHANCER'], it ]
        }
    
    // random TSS
    random_tss_ch = Channel.fromPath(params.random_tss_bed)
        .map{ it ->            
            [ ['name': it.baseName.replaceFirst(/^.*_/,""), 'source': 'GENEHANCER'], it ]
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
        
    /////////////////////////////////////////////////
    // GC CORRECTIONS
    /////////////////////////////////////////////////
    COMPUTEGCBIAS(sample_ch)    
    CORRECTGCBIAS(COMPUTEGCBIAS.out.bam_with_freq)
    // generate bed files for segments
    SEG2BED(CORRECTGCBIAS.out.gc_correct)
    
    /////////////////////////////////////////////////
    // SUBSAMPLE BED FILES
    /////////////////////////////////////////////////   
    
    gain_bam_ch = SEG2BED.out
        .map{ it ->
            [it[0], it[1], it[2], it[3]]
        }
    
    neut_bam_ch = SEG2BED.out
        .map{ it ->
            [it[0], it[1], it[2], it[4]]
        }

    ploidy_bam_ch = gain_bam_ch
        .concat(neut_bam_ch)

    SAMTOOLSFILTERSEG(ploidy_bam_ch)
    neut_and_gain_bam_ch = SAMTOOLSFILTERSEG.out.ploidy_bam
        .groupTuple(by: 0)
        .map{ it ->
            [it[0], it[1][0], it[1][1]]
        }

    SAMTOOLSCOUNTREADS(neut_and_gain_bam_ch)
    SAMTOOLS_SUBSAMPLE(SAMTOOLSCOUNTREADS.out.counts)

    // BAM CHANNELS WITH PLOIDY
    sample_bam_ch = CORRECTGCBIAS.out.gc_correct
        .map{ it ->
            def ploidy = [ type: 'ALL' ]
            [it[0], ploidy, it[1], it[2]]
        }
    
    split_subsample_multiMap = SAMTOOLS_SUBSAMPLE.out.subsample_bam
        .multiMap{ it ->
            neut: [it[0], it[2]]
            gain: [it[0], it[1]]
        }

    neut_bam_ch = split_subsample_multiMap.neut
        .map{ it -> 
            def ploidy_neut = [ type: 'NEUT' ]
            [it[0], ploidy_neut, it[1]]
        }

    gain_bam_ch = split_subsample_multiMap.gain
        .map{ it -> 
            def ploidy_gain = [ type: 'GAIN' ]
            [it[0], ploidy_gain, it[1]]
        }

    
    all_subsample_bam_ch = neut_bam_ch
        .concat(gain_bam_ch)
        .view()
        
    // SAMTOOLSINDEX(all_subsample_bam_ch)

    // concat all produced bams
    // all_sample_bams_ch = CORRECTGCBIAS.out.gc_correct
    //     .map{ it ->
    //         [it[0], it[1], it[2]]
    //     }
    //     .concat(SAMTOOLSINDEX.out.indexed_bam)

    // COVERAGEBAM(all_sample_bams_ch)

    // split again by ALL, NEUT, GAIN
    // split_bw_ch = COVERAGEBAM.out.bw
    //     .multiMap { it ->
    //         all: [it, it[1].baseName =~ 'gc_correct']
    //     }
    
    // split_bw_ch.all.view()

    /////////////////////////////////////////////////
    // TARGET SEGMENTS
    /////////////////////////////////////////////////
    // combine segments and targets
    // SEG2BED.out.ploidy.view()
    // target_sample_ploidy_ch = SEG2BED.out.ploidy
    //     .combine(target_ch)
    //     .view()
    
    // betools intersect segments and targets
    // SEGTARGETINTERSECT(target_sample_ploidy_ch)
    
    // all_targets_ch = SEGTARGETINTERSECT.out.all_targets
    //     .map { it ->
    //         def meta_target = [
    //             name: it[3].name,
    //             source: it[3].source,
    //             ploidy: 'ALL'
    //         ]
    //         [ it[0], it[1], it[2], meta_target, it[4] ]
    //     }

    // gain_targets_ch = SEGTARGETINTERSECT.out.gain_targets
    //     .map { it ->
    //         def meta_target = [
    //             name: it[3].name,
    //             source: it[3].source,
    //             ploidy: 'GAIN'
    //         ]
    //         [ it[0], it[1], it[2], meta_target, it[4] ]
    //     }

    // neut_targets_ch = SEGTARGETINTERSECT.out.neut_targets
    //     .map { it ->
    //         def meta_target = [
    //             name: it[3].name,
    //             source: it[3].source,
    //             ploidy: 'NEUT'
    //         ]
    //         [ it[0], it[1], it[2], meta_target, it[4] ]
    //     }

    // // concat all targets in a single channel
    // sample_with_targets_ch = all_targets_ch
    //     .concat(neut_targets_ch, gain_targets_ch)
    //     .dump(tag: 'sample_with_targets')
    //     .view()
    
    
    // TODO REFACTOR

    
    
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