#!/usr/bin/env nextflow
/*
========================================================================================
FRAGMENTOMICS PIPELINE
========================================================================================
*/

nextflow.enable.dsl = 2

include { FRAGMENTOMICS } from './workflows/fragmentomics.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   PARSE INPUT FILE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

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

    // bam, bai and bw can be null
    return [
        meta, 
        row.bam ? file(row.bam) : null, 
        row.bai ? file(row.bai) : null, 
        row.bw  ? file(row.bw) : null
    ]
}

// Init params
genome_2bit = params.genome_2bit ? Channel.fromPath(params.genome_2bit) : Channel.empty()
chr_sizes = params.chr_sizes ? Channel.fromPath(params.chr_sizes) : Channel.empty()
blacklist_bed = params.blacklist_bed ? Channel.fromPath(params.blacklist_bed) : Channel.empty()

sample_ch = Channel.fromPath(params.input)
    .splitCsv(header:true, sep:',')
    .map{ create_sample_channel(it) }

housekeeping_ch = Channel.fromPath(params.housekeeping_bed)
    .map{ it ->
        [ ['name': 'HouseKeeping', 'source': 'house_keeping_dataset'], it ]
    }

random_tss_ch = Channel.fromPath(params.random_tss_bed)
    .map{ it ->            
        [ ['name': it.baseName.replaceFirst(/^.*_/,""), 'source': 'house_keeping_dataset'], it ]
    }

target_ch = Channel.fromPath(params.targets)
    .splitCsv(header: true, sep:',')
    .map{ create_target_channel(it) }
    .filter{ it ->
        it[1].size() > 0 
    }
    .concat(housekeeping_ch, random_tss_ch)


// MAIN WORKFLOW
workflow {
    
    main:
    FRAGMENTOMICS(
        sample_ch,
        target_ch,
        genome_2bit,
        chr_sizes,
        blacklist_bed
    )
    
    
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
