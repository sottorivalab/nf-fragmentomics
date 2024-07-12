include { BIGWIG_MERGE               } from '../modules/local/ucsc/bigWigMerge/main.nf'
include { BEDGRAPHTOBIGWIG           } from '../modules/local/ucsc/bedGraphToBigWig/main.nf'

workflow BAM_MERGE {
    take:
    all_bw_ch
    gain_bw_ch
    neut_bw_ch
    loss_bw_ch

    main:
    if (params.ploidysplit) 
    {
        // GROUP BY TIMEPOINT
        timepoint_all_bw_ch = all_bw_ch
            .map{ it ->
                tuple(it[0].timepoint, it[0], it[2])
            }
            .groupTuple(by: 0)
            .map{ it ->                
                tuple(it[0], 'ALL', it[1], it[2])
            }

        timepoint_gain_bw_ch = gain_bw_ch
            .map{ it ->
                tuple(it[0].timepoint, it[0], it[2])
            }
            .groupTuple(by: 0)
            .map{ it ->                
                tuple(it[0], 'GAIN', it[1], it[2])
            }

        timepoint_neut_bw_ch = neut_bw_ch
            .map{ it ->
                tuple(it[0].timepoint, it[0], it[2])
            }
            .groupTuple(by: 0)
            .map{ it ->                
                tuple(it[0], 'NEUT', it[1], it[2])
            }
        
        timepoint_loss_bw_ch = loss_bw_ch
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
    else
    {
        // GROUP BY TIMEPOINT
        timepoints_ch = all_bw_ch
            .map{ it ->
                tuple(it[0].timepoint, it[0], it[2])
            }
            .groupTuple(by: 0)
            .map{ it ->                
                tuple(it[0], 'ALL', it[1], it[2])
            }
            .filter{ it ->
                it[2].size() > 1
            }
        
        BIGWIG_MERGE(timepoints_ch)
        BEDGRAPHTOBIGWIG(BIGWIG_MERGE.out.bedgraph)
    }

    // emit:
    
}