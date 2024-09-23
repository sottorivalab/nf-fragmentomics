/*
FRAGMENTOMICS MAIN WORKFLOW
*/

include { BAM_PREPROCESS     } from '../subworkflows/bam_preprocess/main.nf'
// include { TARGET_PROCESS     } from './workflows/target_process.nf'
// include { BAM_MERGE          } from './workflows/bam_merge.nf'


workflow FRAGMENTOMICS {
    take:
        // sample_ch [[ caseid, sampleid, timepoint ], bam, bai, bw]
        sample_ch
        // target_ch [[ name, source ], bed]
        target_ch
        // file
        genome_2bit
        // file
        blacklist_bed

    main:
        /////////////////////////////////////////////////
        // PIPELINE INFO
        /////////////////////////////////////////////////
        log.info """\
        ===================================
        ${params.manifest.name} v${params.manifest.version}
        ===================================

        PARAMS
        -----------------------------------
        input         : ${params.input}
        targets       : ${params.targets}
        outdir        : ${params.outdir}   
        preprocess    : ${params.preprocess}
        bin size      : ${params.bin_size}
        target expand : ${params.target_expand_sx} bp - ${params.target_expand_dx} bp
        bam filter    : ${params.filter_min} bp - ${params.filter_max} bp
        -----------------------------------

        REFERENCE GENOME:
        -----------------------------------
        genome size      : ${params.genome_size}
        genome 2bit      : ${params.genome_2bit}
        blacklist bed    : ${params.blacklist_bed}
        -----------------------------------

        RUNTIME INFO
        -----------------------------------
        started at           : ${workflow.start}
        projectDir           : ${workflow.projectDir}
        workDir              : ${workflow.workDir}
        container            : ${workflow.containerEngine}:${workflow.container}
        config files         : ${workflow.configFiles}
        profile              : ${workflow.profile}
        stubRun              : ${workflow.stubRun}
        run as               : ${workflow.commandLine}
        -----------------------------------
        """
        .stripIndent()

        // BAM PROCESSING
        if (params.preprocess) {
            // remove wiggle from sample channel
            // rerun preprocess for all samples            
            bam_ch = sample_ch
                .map { it ->
                    [it[0], it[1], it[2]]
                }
            
            BAM_PREPROCESS(
                bam_ch,
                genome_2bit,
                blacklist_bed
            )

            wiggle_ch = BAM_PREPROCESS.out.wiggle_ch
        // USE BIG WIGGLES
        } else {
            log.warn("Skipping preprocessing ...")
            wiggle_ch = sample_ch
                .map { it ->
                    [it[0], it[3]]
                }
        }

        // TODO TARGET_PROCESS
        // target_ch.view()

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