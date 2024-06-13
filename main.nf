
include { BAMPEFRAGMENTSIZE  } from './modules/local/bamPEfragmentSize.nf'
include { PLOTCOVERAGE       } from './modules/local/plotCoverage.nf'
include { FILTERBAMBYSIZE    } from './modules/local/filterBamBySize.nf'
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
include { TARGETPLOT         } from "./modules/local/targetPlot.nf"

def create_target_channel(LinkedHashMap row) {
    def meta = [
        name: row.name,
        source: row.source
    ]
    return [meta, row.bed]
}

def create_sample_channel(LinkedHashMap row) {
    // create all at once
    def meta = [
        caseid: row.caseid,
        sampleid: row.sampleid,
        timepoint: row.timepoint
    ]
    return [meta, file(row.bam), file(row.bai), file(row.seg)]
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
    // BAMQC AND FILTER READS BY SIZE 
    /////////////////////////////////////////////////
    BAMPEFRAGMENTSIZE(sample_ch)
    PLOTCOVERAGE(sample_ch)
    FILTERBAMBYSIZE(sample_ch)

    /////////////////////////////////////////////////
    // GC CORRECTIONS
    /////////////////////////////////////////////////
    COMPUTEGCBIAS(FILTERBAMBYSIZE.out.filtered)
    CORRECTGCBIAS(COMPUTEGCBIAS.out.bam_with_freq)
    
    /////////////////////////////////////////////////
    // SUBSAMPLE BED FILES
    /////////////////////////////////////////////////
    // generate bed files for segments
    SEG2BED(CORRECTGCBIAS.out.gc_correct)
    gain_bam_ch = SEG2BED.out
        .map{ it ->
            [it[0], it[1], it[2], it[3]]
        }
    neut_bam_ch = SEG2BED.out
        .map{ it ->
            [it[0], it[1], it[2], it[4]]
        }
    loss_bam_ch = SEG2BED.out
        .map{ it ->
            [it[0], it[1], it[2], it[5]]
        }
    ploidy_bam_ch = gain_bam_ch.concat(neut_bam_ch, loss_bam_ch)
    
    SAMTOOLSFILTERSEG(ploidy_bam_ch)
    ploidy_sub_bam_ch = SAMTOOLSFILTERSEG.out.ploidy_bam
        .groupTuple(by: 0)
        .map{ it ->
            [it[0], it[1][0], it[1][1], it[1][2]]
        }

    // FIXME resume BUG HERE
    // Here sometimes it ignore cached bam files
    // see also: https://www.nextflow.io/blog/2019/troubleshooting-nextflow-resume.html
    
    SAMTOOLSCOUNTREADS(ploidy_sub_bam_ch)    
    SAMTOOLS_SUBSAMPLE(SAMTOOLSCOUNTREADS.out.counts)

    // BAM CHANNELS WITH PLOIDY
    sample_bam_ch = CORRECTGCBIAS.out.gc_correct
        .map{ it ->            
            [it[0], [ type: 'ALL' ], it[1], it[2]]
        }
    
    split_subsample_multiMap = SAMTOOLS_SUBSAMPLE.out.subsample_bam
        .multiMap{ it ->
            neut: [it[0], it[2]]
            gain: [it[0], it[1]]
            loss: [it[0], it[3]]
        }
    
    neut_bam_ch = split_subsample_multiMap.neut
        .map{ it -> 
            def T = [ type: 'NEUT' ]
            [it[0], T , it[1]]
        }

    gain_bam_ch = split_subsample_multiMap.gain
        .map{ it -> 
            def T = [ type: 'GAIN' ]
            [it[0], T, it[1]]
        }
    
    loss_bam_ch = split_subsample_multiMap.loss
        .map{ it ->
            def T = [ type: 'LOSS' ]
            [it[0], T, it[1]]
        }

    all_subsample_bam_ch = neut_bam_ch
        .concat(gain_bam_ch, loss_bam_ch)
        .dump(tag: 'subsamples')        
    
    SAMTOOLSINDEX(all_subsample_bam_ch)

    // concat all produced bams
    all_sample_bams_ch = sample_bam_ch
        .concat(SAMTOOLSINDEX.out.indexed_bam)
        .dump(tag: 'allbams')
    
    COVERAGEBAM(all_sample_bams_ch)
    
    // split again by ALL, NEUT, GAIN
    split_bw_ch = COVERAGEBAM.out.bw
        .branch{
            all:  it[1].type == 'ALL'
            neut: it[1].type == 'NEUT'
            gain: it[1].type == 'GAIN'
        }
    
    // THIS ARE THE BW CHANNELS:
    split_bw_ch.all.dump(tag: 'all_bw')
    split_bw_ch.gain.dump(tag: 'gain_bw')
    split_bw_ch.neut.dump(tag: 'neut_bw')

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

    // targets channel and filter by size
    target_ch = Channel.fromPath(params.targets)
        .splitCsv(header: true, sep:',')
        .map{ create_target_channel(it) }
        .filter{ it ->
            it[1].size() > 0 
        }
        .concat(housekeeping_ch, random_tss_ch)
        .dump(tag: 'targets')
    
    /////////////////////////////////////////////////
    // TARGET SEGMENTS
    /////////////////////////////////////////////////
    // combine segments and targets
    target_sample_ploidy_ch = SEG2BED.out.ploidy
        .map{
            [it[0], it[3], it[4]]        
        }
        .combine(target_ch)
    
    // betools intersect segments and targets
    SEGTARGETINTERSECT(target_sample_ploidy_ch)
   
    all_targets_ch = SEGTARGETINTERSECT.out.all_targets
        .map { it ->
            [ it[0], it[1], [ type: 'ALL' ], it[2] ]
        }

    gain_targets_ch = SEGTARGETINTERSECT.out.gain_targets
        .map { it ->
            [ it[0], it[1], [ type: 'GAIN' ], it[2] ]
        }

    neut_targets_ch = SEGTARGETINTERSECT.out.neut_targets
        .map { it ->
            [ it[0], it[1], [ type: 'NEUT' ], it[2] ]
        }

    // combine bams (ALL) with targets (all)
    all_signal_target_ch = split_bw_ch.all
        .combine(all_targets_ch, by: 0)
    
    gain_signal_target_ch = split_bw_ch.gain
        .combine(gain_targets_ch, by: 0)

    neut_signal_target_ch = split_bw_ch.neut
        .combine(neut_targets_ch, by: 0)

    // concat all and filter for size > 0
    signal_target_ch = all_signal_target_ch
        .concat(gain_signal_target_ch, neut_signal_target_ch)
        .filter{ it ->
            it[5].size() > 0 
        }

    COMPUTEMATRIX(signal_target_ch)
    HEATMAP(COMPUTEMATRIX.out.matrix)
    PEAK_STATS(COMPUTEMATRIX.out.matrix)
    
    sample_peaks_ch = PEAK_STATS.out.peaks
        .map{ it ->
            [ it[0], it[1], it[2], it[3], it[5] ]
        }
        .groupTuple(by: 0)
        .dump(tag: 'sample_peaks')

    // peak report with ./bin/fragmentomics_peakReport.py
    PEAK_REPORT(sample_peaks_ch)

    /*
        ----- PEAK STATS CHANNEL ----------
        
        [
            [caseid:MAYA_12, sampleid:MAYA_12_BL, timepoint:BL], 
            [type:NEUT], 
            [name:YY1, source:GRIFFIN], 
            [type:NEUT], 
            /scratch/davide.rambaldi/nf-fragmentomics_sandbox/work/26/c3e9f55f4b2334f6c0bbbf01370401/MAYA_12_BL_NEUT_YY1_GRIFFIN_peak_data.tsv, 
            /scratch/davide.rambaldi/nf-fragmentomics_sandbox/work/26/c3e9f55f4b2334f6c0bbbf01370401/MAYA_12_BL_NEUT_YY1_GRIFFIN_peak_stats.csv, 
            /scratch/davide.rambaldi/nf-fragmentomics_sandbox/work/26/c3e9f55f4b2334f6c0bbbf01370401/MAYA_12_BL_NEUT_YY1_GRIFFIN_PeakIntegration.pdf
        ]
        
    */

    /////////////////////////////////////////////////
    // HOUSEKEEPING TSS
    /////////////////////////////////////////////////
    // TODO
    // housekeeping_report_ch = PEAK_STATS.out.peaks
    //     .filter{ it ->
    //         it[2].source == "GENEHANCER"
    //     }
    //     .view()
    

    /////////////////////////////////////////////////
    // MULTI SAMPLES
    /////////////////////////////////////////////////
    if (params.multisamples) {
        // GROUP BY TARGET
        // when we have more than one sample (target peak analysis)
        // regroup peak data from different samples by target and target ploidy
        // remove GeneHancer targets
        target_peaks_ch = PEAK_STATS.out.peaks
            .map{ it ->
                [ it[0], it[1], it[2], it[3], it[4] ]
            }
            .groupTuple(by: [2,3])
            .filter{ it ->
                it[2].source != 'GENEHANCER'
            }
        TARGETPLOT(target_peaks_ch)
        
        // GROUP BY TIMEPOINT
        timepoint_all_bw_ch = split_bw_ch.all
            .map{ it ->
                tuple(it[0].timepoint, it[0], it[2])
            }
            .groupTuple(by: 0)
            .map{ it ->                
                tuple(it[0], 'ALL', it[1], it[2])
            }

        timepoint_gain_bw_ch = split_bw_ch.gain
            .map{ it ->
                tuple(it[0].timepoint, it[0], it[2])
            }
            .groupTuple(by: 0)
            .map{ it ->                
                tuple(it[0], 'GAIN', it[1], it[2])
            }

        timepoint_neut_bw_ch = split_bw_ch.neut
            .map{ it ->
                tuple(it[0].timepoint, it[0], it[2])
            }
            .groupTuple(by: 0)
            .map{ it ->                
                tuple(it[0], 'NEUT', it[1], it[2])
            }

        // merge only when we have more than 1 sample (filter)
        timepoints_ch = timepoint_all_bw_ch
            .concat(timepoint_gain_bw_ch, timepoint_neut_bw_ch)
            .filter{ it ->
                it[2].size() > 1
            }
            .view()

        BIGWIG_MERGE(timepoints_ch)
        BEDGRAPHTOBIGWIG(BIGWIG_MERGE.out.bedgraph)
    }
}
