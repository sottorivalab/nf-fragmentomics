// FRAGMENTOMICS PIPELINE
include { BAM_PREPROCESS     } from './workflows/bam_preprocess.nf'
include { TARGET_PROCESS     } from './workflows/target_process.nf'
include { BAM_MERGE          } from './workflows/bam_merge.nf'

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

// MAIN WORKFLOW
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

        multi samples : ${params.multisamples}
        ploidy split  : ${params.ploidysplit}        
        stubRun       : ${workflow.stubRun}
        genome size   : ${params.genome_size}
        target expand : ${params.target_expand_sx} bp - ${params.target_expand_dx} bp

        genome 2bit   : ${params.genome_2bit} 
        chr sizes     : ${params.chr_sizes}
        blacklist     : ${params.blacklist_bed}        
        ===================================
        """
        .stripIndent()
    
    /////////////////////////////////////////////////
    // PARAMS files
    /////////////////////////////////////////////////
    genome_2bit = Channel.fromPath(params.genome_2bit)
    chr_sizes = Channel.fromPath(params.chr_sizes)
    blacklist_bed = Channel.fromPath(params.blacklist_bed)

    /////////////////////////////////////////////////
    // SAMPLES meta: [ caseid, sampleid, timepoint ]
    /////////////////////////////////////////////////
    
    // samples channel
    sample_ch = Channel.fromPath(params.input)
        .splitCsv(header:true, sep:',')
        .map{ create_sample_channel(it) }
        .dump(tag: 'samples')
    
    BAM_PREPROCESS(sample_ch, genome_2bit, blacklist_bed)

    if (params.multisamples) {
        BAM_MERGE(
            BAM_PREPROCESS.out.all_bw_ch,
            BAM_PREPROCESS.out.gain_bw_ch,
            BAM_PREPROCESS.out.neut_bw_ch,
            BAM_PREPROCESS.out.loss_bw_ch
        )
    }

    // /////////////////////////////////////////////////
    // // TARGETS meta: [ name, source ]
    // /////////////////////////////////////////////////

    // // HouseKeeping genes
    // housekeeping_ch = Channel.fromPath(params.housekeeping_bed)
    //     .map{ it ->
    //         [ ['name': 'HouseKeeping', 'source': 'GENEHANCER'], it ]
    //     }
    
    // // random TSS
    // random_tss_ch = Channel.fromPath(params.random_tss_bed)
    //     .map{ it ->            
    //         [ ['name': it.baseName.replaceFirst(/^.*_/,""), 'source': 'GENEHANCER'], it ]
    //     }

    // // targets channel and filter by size
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
    //     BAM_PREPROCESS.out.loss_bw_ch
    // )
}
