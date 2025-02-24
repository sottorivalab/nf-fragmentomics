/*
FRAGMENTOMICS MAIN WORKFLOW
*/

include { BAM_PREPROCESS     } from '../subworkflows/bam_preprocess/main.nf'
include { TARGET_PROCESS     } from '../subworkflows/target_process/main.nf'


workflow FRAGMENTOMICS {
    take:
        // sample_ch [[ caseid, sampleid, timepoint ], bam, bai, bw]
        sample_ch
        // target_ch [bed]
        target_ch
        // file
        genome_2bit
        // file
        blacklist_bed

    main:

        ///////////////////////////////////////////////////
        // VERSION CHANNEL
        ///////////////////////////////////////////////////
        ch_versions = Channel.empty()

        /////////////////////////////////////////////////
        // PIPELINE INFO
        /////////////////////////////////////////////////
        log.info """\
        ===================================
        ${workflow.manifest.name} v${workflow.manifest.version}
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

            wiggle_ch = BAM_PREPROCESS.out.bw

            ch_versions = ch_versions.mix(
                BAM_PREPROCESS.out.versions
            )

        // USE BIG WIGGLES
        } else {
            log.warn("Skipping preprocessing ...")
            wiggle_ch = sample_ch
                .map { it ->
                    [it[0], it[3]]
                }
        }

        TARGET_PROCESS(
            target_ch,
            wiggle_ch,
            blacklist_bed
        )

        ch_versions = ch_versions.mix(
            TARGET_PROCESS.out.versions
        )

    emit:
        versions = ch_versions  // channel: [ path(versions.yml) ]
}