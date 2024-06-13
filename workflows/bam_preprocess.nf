include { BAMPEFRAGMENTSIZE  } from '../modules/local/bamPEfragmentSize.nf'
include { PLOTCOVERAGE       } from '../modules/local/plotCoverage.nf'
include { FILTERBAMBYSIZE    } from '../modules/local/filterBamBySize.nf'
include { COMPUTEGCBIAS      } from '../modules/local/computeGCbias.nf'
include { CORRECTGCBIAS      } from '../modules/local/correctGCbias.nf'
include { SAMTOOLSINDEX      } from '../modules/local/samtoolsIndex.nf'
include { COVERAGEBAM        } from '../modules/local/coverageBam.nf'
include { SEG2BED            } from '../modules/local/seg2bed.nf'
include { SAMTOOLSFILTERSEG  } from "../modules/local/samtoolsFilterSeg.nf"
include { SAMTOOLSCOUNTREADS } from "../modules/local/samtoolsCountReads.nf"
include { SAMTOOLS_SUBSAMPLE } from "../modules/local/samtoolsSubSample.nf"
include { BIGWIG_MERGE       } from '../modules/local/bigWigMerge.nf'
include { BEDGRAPHTOBIGWIG   } from '../modules/local/bedGraphToBigWig.nf'

workflow BAM_PREPROCESS {
    take:
    sample_ch

    main:
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

    // FIXME is here that things are mixed
    ploidy_sub_bam_ch = SAMTOOLSFILTERSEG.out.ploidy_bam
        .groupTuple(by: 0)
        // FIXME I should search file by TAG here DO NOT TRSUT ORDER
        .map{ it ->
            def meta = it[0]
            def gain = it[1].find { el -> el =~ "GAIN" }
            def neut = it[1].find { el -> el =~ "NEUT" }
            def loss = it[1].find { el -> el =~ "LOSS" }
            def X = [it[0], gain, neut, loss]
            return X
        }

    SAMTOOLSCOUNTREADS(ploidy_sub_bam_ch)    
    SAMTOOLS_SUBSAMPLE(SAMTOOLSCOUNTREADS.out.counts)

    // BAM CHANNELS WITH PLOIDY
    sample_bam_ch = CORRECTGCBIAS.out.gc_correct
        .map{ it ->     
            def T = [ type: 'ALL' ]       
            [it[0], T, it[1], it[2]]
        }
    
    split_subsample_multiMap = SAMTOOLS_SUBSAMPLE.out.subsample_bam
        .multiMap{ it ->            
            gain: [it[0], it[1]]
            neut: [it[0], it[2]]
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
            loss: it[1].type == 'LOSS'
        }
    
    /////////////////////////////////////////////////
    // MULTI SAMPLES
    /////////////////////////////////////////////////
    if (params.multisamples) {
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
        
        timepoint_loss_bw_ch = split_bw_ch.neut
            .map{ it ->
                tuple(it[0].timepoint, it[0], it[2])
            }
            .groupTuple(by: 0)
            .map{ it ->                
                tuple(it[0], 'LOSS', it[1], it[2])
            }

        // merge only when we have more than 1 sample (filter)
        timepoints_ch = timepoint_all_bw_ch
            .concat(timepoint_gain_bw_ch, timepoint_neut_bw_ch, timepoint_loss_bw_ch)
            .filter{ it ->
                it[2].size() > 1
            }

        BIGWIG_MERGE(timepoints_ch)
        BEDGRAPHTOBIGWIG(BIGWIG_MERGE.out.bedgraph)
    }

    emit:
    all_bw_ch  = split_bw_ch.all
    gain_bw_ch = split_bw_ch.gain
    neut_bw_ch = split_bw_ch.neut
    loss_bw_ch = split_bw_ch.loss
    ploidy     = SEG2BED.out.ploidy
}