include { BAMPEFRAGMENTSIZE          } from '../modules/local/deeptools/bamPEfragmentSize/main.nf'
include { PLOTCOVERAGE               } from '../modules/local/deeptools/plotCoverage/main.nf'
include { FILTERBAMBYSIZE            } from '../modules/local/samtools/filterBamBySize/main.nf'
include { COMPUTEGCBIAS              } from '../modules/local/deeptools/computeGCbias/main.nf'
include { CORRECTGCBIAS              } from '../modules/local/deeptools/correctGCbias/main.nf'
include { SEG2BED                    } from '../modules/local/seg2bed/main.nf'
include { SAMTOOLSFILTERSEG          } from "../modules/local/samtools/filterSeg/main.nf"
include { SAMTOOLS_PLOIDY_COUNTREADS } from "../modules/local/samtools/ploidyCountReads/main.nf"
include { SAMTOOLS_SUBSAMPLE         } from "../modules/local/samtools/subSample/main.nf"
include { SAMTOOLSINDEX              } from '../modules/local/samtools/index/main.nf'
include { SAMTOOLS_COUNTREADS        } from "../modules/local/samtools/countReads/main.nf"
include { COVERAGEBAM                } from '../modules/local/deeptools/coverageBam/main.nf'

workflow BAM_PREPROCESS {
    take:
    sample_ch
    genome_2bit
    blacklist_bed

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
    COMPUTEGCBIAS(
        FILTERBAMBYSIZE.out.filtered.combine(genome_2bit)
    )    
    CORRECTGCBIAS(
        COMPUTEGCBIAS.out.bam_with_freq.combine(genome_2bit)
    )
    
    /////////////////////////////////////////////////
    // SUBSAMPLE BED FILES
    /////////////////////////////////////////////////
    if (params.ploidysplit) 
    {
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
        
        // FIXME this can reduce a lot the sample size in case of a very small group:
        // VALE_38:
        //  VALE_38_BR_LOSS.bam, 64.126
        //  VALE_38_BR_NEUT.bam, 677.806.402
        //  VALE_38_BR_GAIN.bam, 11.121.902                

        SAMTOOLSFILTERSEG(ploidy_bam_ch)
        
        ploidy_sub_bam_ch = SAMTOOLSFILTERSEG.out.ploidy_bam
            .groupTuple(by: 0)
            .map{ it ->
                def meta = it[0]
                def gain = it[1].find { el -> el =~ "GAIN" }
                def neut = it[1].find { el -> el =~ "NEUT" }
                def loss = it[1].find { el -> el =~ "LOSS" }
                def X = [it[0], gain, neut, loss]
                return X
            }

        if (params.subsample_ploidy) {

            SAMTOOLS_PLOIDY_COUNTREADS(ploidy_sub_bam_ch)   
            SAMTOOLS_SUBSAMPLE(SAMTOOLS_PLOIDY_COUNTREADS.out.counts)
            split_subsample_multiMap = SAMTOOLS_SUBSAMPLE.out.subsample_bam
                .multiMap{ it ->            
                    gain: [it[0], it[1]]
                    neut: [it[0], it[2]]
                    loss: [it[0], it[3]]
                }                        

        } else {
            split_subsample_multiMap = ploidy_sub_bam_ch.multiMap{ it ->
                gain: [it[0], it[1]]
                neut: [it[0], it[2]]
                loss: [it[0], it[3]]
            }
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
            
        // BAM CHANNELS WITH PLOIDY
        sample_bam_ch = CORRECTGCBIAS.out.gc_correct
            .map{ it ->     
                def T = [ type: 'ALL' ]       
                [it[0], T, it[1], it[2]]
            }

        all_subsample_bam_ch = neut_bam_ch
            .concat(gain_bam_ch, loss_bam_ch)
            .dump(tag: 'subsamples')        
        
        SAMTOOLSINDEX(all_subsample_bam_ch)

        // concat all produced bams
        all_sample_bams_ch = sample_bam_ch
            .concat(SAMTOOLSINDEX.out.indexed_bam)        
            .dump(tag: 'allbams')

        // filter for bam size        
        SAMTOOLS_COUNTREADS(all_sample_bams_ch)
        
        filtered_bams_ch = SAMTOOLS_COUNTREADS.out.bamcount
            .filter{ it ->                
                int read_count = file(it[4]).readLines()[0].toInteger()
                if (read_count <= 0) println ">>> WARNING: file ${it[2]} does not have enough reads and will not be included"
                read_count > 0
            }
            .map{ it ->
                [it[0], it[1], it[2], it[3]]
            }            

        // Coverage bam
        COVERAGEBAM(filtered_bams_ch.combine(blacklist_bed))
    
        // split again by ALL, NEUT, GAIN
        split_bw_ch = COVERAGEBAM.out.bw
            .branch{
                all:  it[1].type == 'ALL'
                neut: it[1].type == 'NEUT'
                gain: it[1].type == 'GAIN'
                loss: it[1].type == 'LOSS'
            }
        
        bw_all  = split_bw_ch.all
        bw_gain = split_bw_ch.gain
        bw_loss = split_bw_ch.loss
        bw_neut = split_bw_ch.neut
        ploidy_ch = SEG2BED.out.ploidy
    } 
    // no ploidy split
    else 
    {
        // BAM CHANNELS WITH PLOIDY ALL only
        sample_bam_ch = CORRECTGCBIAS.out.gc_correct
            .map{ it ->     
                def T = [ type: 'ALL' ]       
                [it[0], T, it[1], it[2]]
            }
        
        COVERAGEBAM(sample_bam_ch.combine(blacklist_bed))

        bw_all = COVERAGEBAM.out.bw
        bw_gain = Channel.empty()
        bw_loss = Channel.empty()
        bw_neut = Channel.empty()
        ploidy_ch = Channel.empty()
    }
    
    emit:
    all_bw_ch  = bw_all
    gain_bw_ch = bw_gain
    neut_bw_ch = bw_neut
    loss_bw_ch = bw_loss
    ploidy     = ploidy_ch
}