#!/usr/bin/env nextflow
/*
========================================================================================
FRAGMENTOMICS PIPELINE
========================================================================================
*/

nextflow.enable.dsl = 2

include { FRAGMENTOMICS } from './workflows/fragmentomics.nf'

def create_target_channel(LinkedHashMap row) {
    def meta = [
        name: row.name,
        source: row.source
    ]
    return [meta, file(row.bed)]
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

// MAIN WORKFLOW
workflow {
    
    main:
    // Init param files
    genome_2bit = params.genome_2bit ? Channel.fromPath(params.genome_2bit) : Channel.empty()
    blacklist_bed = params.blacklist_bed ? Channel.fromPath(params.blacklist_bed) : Channel.empty()

    // samples channel
    sample_ch = Channel.fromPath(params.input)
        .splitCsv(header:true, sep:',')
        .map{ create_sample_channel(it) }

    // targets channel
    target_ch = Channel.fromPath(params.targets)
        .splitCsv(header: true, sep:',')
        .map{ create_target_channel(it) }
        
    // filter targets for lines if not stubrun
    if (workflow.stubRun == false) {
        target_ch = target_ch
            .filter{ it ->
                it[1].readLines().size() > 1
            }
    }

    FRAGMENTOMICS(
        sample_ch,
        target_ch,
        genome_2bit,
        blacklist_bed
    )    

    // collect versions in a single file simple mode
    FRAGMENTOMICS.out.versions
        .unique()
        .map { version_file ->
            version_file.text
        }
        .unique()
        .view()
}
