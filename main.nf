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

// Init param files
genome_2bit = params.genome_2bit ? Channel.fromPath(params.genome_2bit) : Channel.empty()
blacklist_bed = params.blacklist_bed ? Channel.fromPath(params.blacklist_bed) : Channel.empty()

// samples channel
sample_ch = Channel.fromPath(params.input)
    .splitCsv(header:true, sep:',')
    .map{ create_sample_channel(it) }

target_ch = Channel.fromPath(params.targets)
    .splitCsv(header: true, sep:',')
    .map{ create_target_channel(it) }
    .filter{ it ->
        it[1].size() > 0 
    }
    .view()

// MAIN WORKFLOW
workflow {
    
    main:
    FRAGMENTOMICS(
        sample_ch,
        target_ch,
        genome_2bit,
        blacklist_bed
    )

}
