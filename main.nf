#!/usr/bin/env nextflow
/*
========================================================================================
FRAGMENTOMICS PIPELINE
========================================================================================
*/

nextflow.enable.dsl = 2

include { FRAGMENTOMICS } from './workflows/fragmentomics.nf'

// include { BAM_PREPROCESS     } from './workflows/bam_preprocess.nf'
// include { TARGET_PROCESS     } from './workflows/target_process.nf'
// include { BAM_MERGE          } from './workflows/bam_merge.nf'




// def create_target_channel(LinkedHashMap row) {
//     def meta = [
//         name: row.name,
//         source: row.source
//     ]
//     return [meta, row.bed]
// }

// def create_sample_channel(LinkedHashMap row) {
//     // create all at once
//     def meta = [
//         caseid: row.caseid,
//         sampleid: row.sampleid,
//         timepoint: row.timepoint
//     ]
//     return [meta, file(row.bam), file(row.bai), file(row.seg)]
// }

// MAIN WORKFLOW
workflow {

    main:
    FRAGMENTOMICS()

    
    /////////////////////////////////////////////////
    // PARAMS files
    /////////////////////////////////////////////////
    // genome_2bit = Channel.fromPath(params.genome_2bit)
    // chr_sizes = Channel.fromPath(params.chr_sizes)
    // blacklist_bed = Channel.fromPath(params.blacklist_bed)

    /////////////////////////////////////////////////
    // SAMPLES meta: [ caseid, sampleid, timepoint ]
    /////////////////////////////////////////////////
    
    // samples channel
    // sample_ch = Channel.fromPath(params.input)
    //     .splitCsv(header:true, sep:',')
    //     .map{ create_sample_channel(it) }
    //     .dump(tag: 'samples')
    
    // BAM_PREPROCESS(sample_ch, genome_2bit, blacklist_bed)

    // if (params.multisamples) {
    //     BAM_MERGE(
    //        BAM_PREPROCESS.out.all_bw_ch,
    //        BAM_PREPROCESS.out.gain_bw_ch,
    //        BAM_PREPROCESS.out.neut_bw_ch,
    //        BAM_PREPROCESS.out.loss_bw_ch,
    //        chr_sizes
    //     )
    // }

    /////////////////////////////////////////////////
    // TARGETS meta: [ name, source ]
    /////////////////////////////////////////////////

    // HouseKeeping genes
    // housekeeping_ch = Channel.fromPath(params.housekeeping_bed)
    //     .map{ it ->
    //         [ ['name': 'HouseKeeping', 'source': 'GENEHANCER'], it ]
    //     }
    
    // random TSS
    // random_tss_ch = Channel.fromPath(params.random_tss_bed)
    //     .map{ it ->            
    //         [ ['name': it.baseName.replaceFirst(/^.*_/,""), 'source': 'GENEHANCER'], it ]
    //     }

    // targets channel and filter by size
    // target_ch = Channel.fromPath(params.targets)
    //     .splitCsv(header: true, sep:',')
    //     .map{ create_target_channel(it) }
    //     .filter{ it ->
    //         it[1].size() > 0 
    //     }
    //     .concat(housekeeping_ch, random_tss_ch)
    //     .dump(tag: 'targets')

    // TARGET_PROCESS(
    //     target_ch, 
    //     BAM_PREPROCESS.out.ploidy, 
    //     BAM_PREPROCESS.out.all_bw_ch,
    //     BAM_PREPROCESS.out.gain_bw_ch,
    //     BAM_PREPROCESS.out.neut_bw_ch,
    //     BAM_PREPROCESS.out.loss_bw_ch,
    //     blacklist_bed
    // )
}
