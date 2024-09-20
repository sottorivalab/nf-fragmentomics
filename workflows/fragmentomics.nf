/*
FRAGMENTOMICS MAIN WORKFLOW
*/
workflow FRAGMENTOMICS {
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
        bin size      : ${params.bin_size}
        target expand : ${params.target_expand_sx} bp - ${params.target_expand_dx} bp
        bam filter    : ${params.filter_min} bp - ${params.filter_max} bp
        -----------------------------------

        REFERENCE GENOME:
        -----------------------------------
        genome size      : ${params.genome_size}
        genome 2bit      : ${params.genome_2bit}
        chr sizes        : ${params.chr_sizes}
        -----------------------------------

        ANNOTATION FILES:
        -----------------------------------
        housekeeping bed : ${params.housekeeping_bed}
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
}